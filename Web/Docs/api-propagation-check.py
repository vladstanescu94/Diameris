#!/usr/bin/env python3
"""Does the LIVE server actually implement the rulings in DECISIONS.md?

Written after discovering that 12 of 13 corrections had landed in documents and
messages but not in code — the server had been built against pre-correction docs.
Docs are not code. This script is the difference.

Run:  python3 Web/Docs/api-propagation-check.py
Needs the server up:  cd Web/Server && ./.build/debug/DiamerisServer

Exit 0 = every ruling propagated. Non-zero = the count still outstanding.
Add a check here whenever a new API-affecting ruling is made.
"""

from __future__ import annotations  # Xcode's bundled python is 3.9

import json
import sys
import urllib.error
import urllib.request

# Default target is the real server; `--base-url` (or DIAMERIS_BASE_URL) points the gate at an
# isolated instance so it can seed and reset without wiping a store someone else is driving (R29).
#   python3 api-propagation-check.py --base-url http://127.0.0.1:8081
import os


def _base_url() -> str:
    args = sys.argv[1:]
    for index, arg in enumerate(args):
        if arg == "--base-url" and index + 1 < len(args):
            return args[index + 1].rstrip("/")
        if arg.startswith("--base-url="):
            return arg.split("=", 1)[1].rstrip("/")
    return os.environ.get("DIAMERIS_BASE_URL", "http://127.0.0.1:8080").rstrip("/")


BASE = _base_url()
URL = f"{BASE}/api/state"

# Ground-truth seed, matching GROUND-TRUTH.md and API-CONTRACT.md §onboarding/complete.
# The script SEEDS this itself rather than assuming the store already holds it — an earlier
# version silently dropped from 20/25 to 13/25 the moment anyone called POST /api/reset,
# because its numeric assertions depended on state it did not establish. Same class of hidden
# assumption the Reviewer found in its own account-keyed test ids: an instrument that assumes
# its fixture is an instrument that reports the fixture, not the code.
A_MAIN = "AAAAAAAA-0000-0000-0000-000000000001"
A_EMERG = "BBBBBBBB-0000-0000-0000-000000000002"
A_SAVE = "CCCCCCCC-0000-0000-0000-000000000003"

SEED = {
    "name": "Vlad",
    "currencyCode": "RON",
    "monthlyIncome": "9000",
    "accounts": [
        {"id": A_MAIN, "name": "Main Account", "purpose": "Where your salary lands",
         "accountType": "primary", "isPrimary": True, "isPrimarySavings": False,
         "currentBalance": "0"},
        {"id": A_EMERG, "name": "Emergency Fund",
         "purpose": "Protects you from unexpected expenses",
         "accountType": "emergency", "isPrimary": False, "isPrimarySavings": False,
         "emergencyMultiplier": 3, "currentBalance": "0"},
        {"id": A_SAVE, "name": "Savings", "purpose": "For building wealth over time",
         "accountType": "savings", "isPrimary": False, "isPrimarySavings": True,
         "currentBalance": "0"},
    ],
    "expenses": [
        {"id": "E1000000-0000-0000-0000-000000000001", "name": "Food", "amount": "1200",
         "frequency": "monthly", "icon": "cart.fill", "isEnabled": True},
        {"id": "E2000000-0000-0000-0000-000000000002", "name": "Rent", "amount": "2500",
         "frequency": "monthly", "icon": "house.fill", "isEnabled": True},
        {"id": "E3000000-0000-0000-0000-000000000003", "name": "Gas", "amount": "450",
         "frequency": "monthly", "icon": "fuelpump.fill", "isEnabled": True},
        {"id": "E4000000-0000-0000-0000-000000000004", "name": "Streaming", "amount": "120",
         "frequency": "monthly", "icon": "tv.fill", "isEnabled": True},
    ],
    "savings": {
        "percentage": 0.25, "boostEnabled": False, "boostMultiplier": 3,
        "allocationMode": "prioritized", "savingsInputMode": "percentage",
        "fixedAmount": "0",
        "splitEmergencyInputMode": "fixedAmount", "splitEmergencyAmount": "0",
        "splitEmergencyPercentage": 0.1,
        "splitSavingsInputMode": "fixedAmount", "splitSavingsAmount": "0",
        "splitSavingsPercentage": 0.15,
    },
    "remainingMoneyDestination": "primarySavings",
}

results: list[tuple[bool, str, str, str]] = []


def check(ruling: str, name: str, ok: bool, detail: str = "") -> None:
    results.append((ok, ruling, name, detail))


def post(path: str, body: dict | None = None) -> int:
    data = json.dumps(body).encode() if body is not None else b"{}"
    req = urllib.request.Request(
        f"{BASE}{path}", data=data, method="POST",
        headers={"Content-Type": "application/json",
                 "X-Diameris-Now": "2026-08-06T12:00:00Z"},
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as r:
            return r.status
    except urllib.error.HTTPError as exc:
        return exc.code
    except Exception:  # noqa: BLE001
        return 0


# --- seed deterministically -------------------------------------------------
reset_status = post("/api/reset")
seed_status = post("/api/onboarding/complete", SEED)
check("harness", "POST /api/reset works", reset_status == 200, f"status={reset_status}")
check("harness", "POST /api/onboarding/complete seeds ground truth",
      seed_status in (200, 201), f"status={seed_status} — numeric checks below depend on it")

try:
    req = urllib.request.Request(URL, headers={"X-Diameris-Now": "2026-08-06T12:00:00Z"})
    with urllib.request.urlopen(req, timeout=10) as r:
        state = json.load(r)
except Exception as exc:  # noqa: BLE001 - operator-facing tool
    print(f"FAIL: cannot reach {URL} — is the server running?\n  {exc}")
    sys.exit(99)

blob = json.dumps(state)
ref = state.get("reference", {})
accounts = state.get("accounts", [])
summary = state.get("dashboard", {}).get("summary", {})

# --- R12: palettes are server-served, in source order, complete -------------
icons = ref.get("expenseIcons") or []
check("R12", "reference.expenseIcons has 37 entries", len(icons) == 37,
      f"len={len(icons)}, last={icons[-1] if icons else None!r}")
check("R12", "reference.expenseIcons ends at 'sparkles'",
      bool(icons) and icons[-1] == "sparkles",
      "truncating at creditcard.fill means it was built from the 18-icon miscount")
check("R12", "reference.categoryIcons has 12 entries",
      len(ref.get("categoryIcons") or []) == 12)
check("R12", "reference.categoryColors has 10 entries",
      len(ref.get("categoryColors") or []) == 10)

# --- R13: slider positions precomputed, plus the step constant -------------
check("R13", "savingsSliderPositions served", "savingsSliderPositions" in blob,
      "without this the slider needs per-frame client arithmetic (violates R2)")
check("R13", "savingsConstants carries a step",
      "step" in json.dumps(ref.get("savingsConstants", {})),
      "the positions table cannot be authored without knowing the increment")

# --- R14 -------------------------------------------------------------------
check("R14", "every account has isReconcilable",
      bool(accounts) and all("isReconcilable" in a for a in accounts),
      "else the client hardcodes the emergency|savings|personal rule")
check("R14", "wasLastMonthDisplay served", "wasLastMonthDisplay" in blob)

# --- R18: the closed set ---------------------------------------------------
check("R18.1", "split resolved amounts + scaleRatio",
      "scaleRatio" in blob and "wasScaledDown" in blob,
      "Split mode is unbuildable under R2 without resolved per-side amounts")
check("R18.2", "emergencyTargetUncapped served", "emergencyTargetUncapped" in blob)
check("R18.2", "isCapActive served", "isCapActive" in blob)
check("R18.3", "emergencyMultiplierOptions served", "emergencyMultiplierOptions" in blob,
      "4 discrete options with captions; a [3,6] range cannot produce them")
check("R18.9", "accountSuggestions served", "accountSuggestions" in blob)
check("R18", "boostedPercentDisplay served", "boostedPercentDisplay" in blob)

# --- R23: the subtitle is 2-3 coloured parts, NOT one padded string --------
bad = [a.get("subtitle", "") for a in accounts if "  " in (a.get("subtitle") or "")]
check("R23", "no double-spaced subtitle", not bad, f"found {bad!r}")

# --- R7: formatter locale pinned server-side -------------------------------
editing = (summary.get("personalSpending") or {}).get("editing")
check("R7", "editing uses '.' not ','", editing is not None and "," not in editing,
      f"editing={editing!r} — pin en_US_POSIX in the SERVER's Money assembly, not Packages/")

# --- R20: full doubles served for geometry ---------------------------------
emergency = [a for a in accounts if a.get("accountType") == "emergency"]
check("R20", "emergencyProgress served as a full double",
      bool(emergency) and isinstance(emergency[0].get("emergencyProgress"), float),
      f"={emergency[0].get('emergencyProgress') if emergency else None}")

# --- Numeric parity: these must never regress ------------------------------
expected = {
    "income": "9,000 RON",
    "expenses": "4,270 RON",
    "savings": "1,182 RON",
    "personalSpending": "3,548 RON",
}
for field, want in expected.items():
    got = (summary.get(field) or {}).get("display")
    check("GT", f"summary.{field} == {want}", got == want, f"got {got!r}")

breakdown = {r.get("name"): r.get("percent")
             for r in state.get("dashboard", {}).get("expenseBreakdown", [])}
for name, want in (("Rent", 58), ("Food", 28), ("Gas", 10), ("Streaming", 2)):
    check("GT", f"breakdown {name} == {want}% (truncated)",
          breakdown.get(name) == want, f"got {breakdown.get(name)!r}")

# --- R17: the dev clock header must actually reach currentMonthDisplay ------
try:
    req = urllib.request.Request(URL, headers={"X-Diameris-Now": "2026-01-15T12:00:00Z"})
    with urllib.request.urlopen(req, timeout=10) as r:
        pinned = json.load(r).get("dashboard", {}).get("currentMonthDisplay")
except Exception:  # noqa: BLE001
    pinned = None
check("R17", "X-Diameris-Now pins currentMonthDisplay", pinned == "January 2026",
      f"got {pinned!r} — without this the Dashboard title assertion tracks the wall clock")

# --- report ----------------------------------------------------------------
failed = [r for r in results if not r[0]]
for ok, ruling, name, detail in results:
    line = f"  {'PASS' if ok else 'FAIL'}  [{ruling}] {name}"
    if not ok and detail:
        line += f"\n          {detail}"
    print(line)

print(f"\n{len(results) - len(failed)}/{len(results)} propagated; {len(failed)} outstanding")
sys.exit(0 if not failed else min(len(failed), 98))
