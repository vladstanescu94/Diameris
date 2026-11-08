#!/usr/bin/env python3
"""
Generate Web/Client/src/locales/{en,ro}.json from the iOS String Catalogs.

Why this exists
---------------
The five `.xcstrings` catalogs hold 353 rows (298 distinct keys). Hand-transcribing them is
precisely where silent drift enters — a Romanian string that reads plausibly but is not the
one the shipped app displays. So the bundles are GENERATED, and the catalogs stay the single
source of truth. See `Web/Docs/LOCALIZATION.md`.

Run from the repo root:   python3 Web/gen-locales.py
Verify without writing:   python3 Web/gen-locales.py --check     (exit 1 if stale)

Rules implemented
-----------------
1. Namespaced per source catalog (`app`, `domain`, `onboarding`, `dashboard`, `expenses`),
   because a string resolves against the bundle of the module that renders it, and 39 keys
   appear in more than one catalog. LOCALIZATION.md §2.

2. EN value = the catalog's explicit `en` entry, else the key itself (which IS the English
   source string — that is the iOS fallback). The `expenses` catalog has zero `en` entries by
   design, so all of its English comes from the keys.

3. RO value = the catalog's explicit `ro` entry. If absent the key is OMITTED from ro.json, so
   `i18n.ts` warns and falls back to English — visible in dev rather than silently wrong.

4. UNREACHABLE ENTRIES ARE DROPPED (LOCALIZATION.md §3.4, from a systematic sweep of all 353
   rows). `.localized` names a *lookup*; whether it resolves depends on which bundle the call
   site binds AND whether that catalog holds the key. Two hazard classes are removed:

   Class A (`ORPHANS`) — the copy carries a DIFFERENT Romanian than the module that actually
   produces the lookup, so serving it renders the wrong Romanian. This matters because
   `i18n.ts` falls back `requested-ns → app → key`: leaving `app.Other = "Altele"` in place
   would let a component that asks for the wrong namespace render "Altele" where iOS shows
   "Altul" — in Romanian only, on a screen that looks perfect in English. Dropping them means
   there is nothing wrong left for the fallback to find.

   Class B (`DEAD_TRANSLATIONS`) — the copy HAS Romanian but the producing module's catalog has
   NO entry, so iOS falls back to the English key. Serving the Romanian would render Romanian
   where iOS shows English: a silent "improvement", which R26a forbids. Only the `ro` value is
   dropped; the `en` entry stays so the key still renders.

5. HAND OVERRIDES are preserved. 11 keys have no Romanian in any catalog (mostly format
   scaffolding like `%lld%%`, plus `Cancel`, for which iOS supplies a system translation the
   web does not get for free). Any Romanian already present in ro.json for such a key is kept
   and reported, so a deliberate human translation is never clobbered by a regeneration.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "Web/Client/src/locales"

CATALOGS: list[tuple[str, str]] = [
    ("app", "Diameris/Resources/Localizable.xcstrings"),
    ("domain", "Packages/Core/Domain/Sources/Domain/Resources/Localizable.xcstrings"),
    ("onboarding", "Packages/Features/Onboarding/Sources/Onboarding/Resources/Localizable.xcstrings"),
    ("dashboard", "Packages/Features/Dashboard/Sources/Dashboard/Resources/Localizable.xcstrings"),
    ("expenses", "Packages/Features/Expenses/Sources/Expenses/Resources/Localizable.xcstrings"),
]

# Unreachable catalog entries, from the systematic sweep in LOCALIZATION.md §3.4.
# Mapping is key -> the ONE namespace allowed to keep it (the module whose code actually
# produces the lookup). Every other namespace's copy is removed.
#
# Class A — the orphan carries a DIFFERENT Romanian than the producing module, so serving it
# renders the wrong Romanian.
ORPHANS: dict[str, str] = {
    "Other": "domain",                            # app had "Altele"; iOS renders domain's "Altul"
    "For building wealth over time": "domain",    # onboarding variant is never read
    "Receives savings after emergency": "domain", # onboarding variant is never read
}

# Class B — the orphan HAS Romanian but the producing module's catalog has NO entry, so iOS
# falls back to the English key. Shipping the Romanian would render Romanian where iOS shows
# English: a silent "improvement", which R26a forbids. Dropped from EVERY namespace.
#
#   "Monthly"/"Annual" — produced by Domain's `Frequency.displayName` ("Monthly".localized),
#     and Domain's catalog lacks both. The "Lunar"/"Anual" values live only in `expenses`,
#     which that call site never reads. iOS therefore shows "Monthly" / "Annual" in Romanian.
#     ⚠️ `expenses.Annual` is the one exception and is NOT dropped: `ExpenseItemRow.swift:60`
#     has a genuine `"Annual".localized` binding the Expenses bundle for the "(Annual)"
#     caption, so "(Anual)" is correct there — under a segment still reading "Annual".
#   "Amount" — produced by SharedUI's `String(localized: "Amount")`, which passes NO bundle and
#     so resolves against `.main`; the app catalog has no entry. iOS shows "Amount".
#   Variant mismatch (G7). Xcode re-extracted two keys when the specifier changed, leaving a
#     TRANSLATED stale variant beside an UNTRANSLATED live one. Swift renders `Int`
#     interpolation as `%lld`, so the live keys are the `%lld` forms — and those have no `ro`,
#     which is why iOS shows English here. The `%d` / `%@` variants are unreachable, but they
#     are one keystroke away from being requested by mistake, and they *do* carry Romanian:
#         'Step %d of %d'                = 'Pasul %d din %d'      (live key: 'Step %lld of %lld')
#         'Target: %@× monthly income'   = 'Țintă: %@× venit lunar'
#                                          (live key: 'Target: %lld× monthly income')
#     Dropping their RO makes the mistake render English — i.e. correctly — instead of Romanian.
DEAD_TRANSLATIONS: set[tuple[str, str]] = {
    ("expenses", "Monthly"),
    ("expenses", "Amount"),
    ("dashboard", "Step %d of %d"),
    ("dashboard", "Target: %@× monthly income"),
}


def value_for(entry: dict, lang: str) -> str | None:
    """The string for `lang`, or None. Plural/device variations are not flattened."""
    loc = entry.get("localizations", {}).get(lang)
    if not loc:
        return None
    unit = loc.get("stringUnit")
    if unit:
        return unit.get("value")
    if "variations" in loc:
        return None  # no variation keys ship today; assert below if that changes
    return None


def has_variations(entry: dict, lang: str) -> bool:
    loc = entry.get("localizations", {}).get(lang)
    return bool(loc and "variations" in loc)


def build() -> tuple[dict, dict, list[str]]:
    en: dict[str, dict[str, str]] = {}
    ro: dict[str, dict[str, str]] = {}
    notes: list[str] = []

    for ns, rel in CATALOGS:
        path = ROOT / rel
        catalog = json.loads(path.read_text())
        assert catalog.get("sourceLanguage") == "en", f"{rel}: unexpected sourceLanguage"
        strings = catalog["strings"]
        en[ns], ro[ns] = {}, {}

        for key in sorted(strings):
            entry = strings[key]

            owner = ORPHANS.get(key)
            if owner is not None and owner != ns:
                notes.append(f"dropped orphan  {ns}.{key!r} (only {owner} can render)")
                continue

            if has_variations(entry, "en") or has_variations(entry, "ro"):
                notes.append(f"NEEDS REVIEW    {ns}.{key!r} uses plural/device variations")

            en[ns][key] = value_for(entry, "en") or key
            ro_value = value_for(entry, "ro")
            if (ns, key) in DEAD_TRANSLATIONS:
                notes.append(
                    f"dropped dead ro {ns}.{key!r} = {ro_value!r} (iOS renders the English key here)"
                )
                ro_value = None
            if ro_value is not None:
                ro[ns][key] = ro_value

    return en, ro, notes


def merge_hand_overrides(ro: dict, notes: list[str]) -> dict:
    """Keep any human-authored Romanian for keys the catalogs leave untranslated."""
    existing_path = OUT_DIR / "ro.json"
    if not existing_path.exists():
        return ro
    existing = json.loads(existing_path.read_text())
    for ns, entries in existing.items():
        if ns not in ro:
            continue
        for key, value in entries.items():
            if key in ORPHANS and ORPHANS[key] != ns:
                continue  # never resurrect a dropped orphan
            if (ns, key) in DEAD_TRANSLATIONS:
                continue  # nor a dead translation
            if key not in ro[ns]:
                ro[ns][key] = value
                notes.append(f"kept override   ro.{ns}.{key!r} = {value!r} (no catalog ro)")
    return ro


def dump(obj: dict) -> str:
    ordered = {ns: obj[ns] for ns, _ in CATALOGS}
    return json.dumps(ordered, ensure_ascii=False, indent=2, sort_keys=False) + "\n"


def main() -> int:
    check_only = "--check" in sys.argv
    en, ro, notes = build()
    ro = merge_hand_overrides(ro, notes)
    en_text, ro_text = dump(en), dump(ro)

    if check_only:
        stale = [
            name
            for name, text in (("en.json", en_text), ("ro.json", ro_text))
            if not (OUT_DIR / name).exists() or (OUT_DIR / name).read_text() != text
        ]
        if stale:
            print(f"STALE: {', '.join(stale)} — run: python3 Web/gen-locales.py", file=sys.stderr)
            return 1
        print("locales up to date")
        return 0

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUT_DIR / "en.json").write_text(en_text)
    (OUT_DIR / "ro.json").write_text(ro_text)

    for note in notes:
        print(f"  {note}")
    print()
    total_en = sum(len(v) for v in en.values())
    total_ro = sum(len(v) for v in ro.values())
    for ns, _ in CATALOGS:
        missing = sorted(set(en[ns]) - set(ro[ns]))
        suffix = f"  missing ro: {len(missing)}" if missing else ""
        print(f"  {ns:<11} en={len(en[ns]):<4} ro={len(ro[ns]):<4}{suffix}")
    print(f"\n  TOTAL       en={total_en}  ro={total_ro}   (353 rows - 4 orphan copies = 349 expected)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
