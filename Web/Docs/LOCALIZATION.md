# Localization Inventory — Diameris

Generated directly from the app's String Catalogs. **Regenerate, don't hand-edit.**

The project uses **source-string-as-key**: the English literal in Swift *is* the lookup key, via
`"...".localized` (a per-module extension binding `bundle: .module`) or `String(localized:bundle:)`.

## 1. There are FIVE catalogs, not four

> ⚠️ **Correction to `DECISIONS.md` R4.** R4 lists four catalogs (Domain, Onboarding, Dashboard,
> Expenses) and omits **`Diameris/Resources/Localizable.xcstrings`** — the main app target's catalog,
> **59 keys**. That catalog owns the entire **Settings sheet**, the **AccountEditorSheet**, the three
> **tab labels** and the **Insights** placeholder. Building the union from four catalogs would ship
> Settings with no Romanian at all. All five are inventoried below.

| # | Namespace | Package | Bundle at runtime | Keys | EN | RO | Owns |
|---|---|---|---|---|---|---|---|
| 1 | `app` | Main app target | `.main` | 59 | 54 | 54 | Settings sheet, AccountEditorSheet, tab labels, Insights placeholder |
| 2 | `domain` | Core/Domain | `.module` (Domain) | 29 | 29 | 29 | Enum displayNames & descriptions: AccountType, AllocationMode, SavingsInputMode, RemainingMoneyDestination, Frequency; AccountEntry factory names/purposes |
| 3 | `onboarding` | Features/Onboarding | `.module` (Onboarding) | 169 | 169 | 169 | All 7 onboarding screens + their components |
| 4 | `dashboard` | Features/Dashboard | `.module` (Dashboard) | 41 | 38 | 37 | Dashboard tab cards + the 3-step New Month flow |
| 5 | `expenses` | Features/Expenses | `.module` (Expenses) | 55 | 0 | 53 | Expenses tab, AddExpenseSheet, CategoryManagementView, AddCategorySheet |
| | **TOTAL** | | | **353** | **290** | **342** |  |

`sourceLanguage` is `en` and `version` `1.0` in all five.

**353 is the row-sum, not the number of distinct strings.** Because 39 keys appear in more than one
catalog (§3), the five catalogs hold **298 distinct keys** — 259 in exactly one catalog, 39 shared.
A namespaced bundle has **353 entries** (each namespace keeps its own copy); a hypothetical flat bundle
would have 298 and would have silently resolved 39 collisions for you.

**Expected entry count in the generated `en.json`: 349.** That is 353 rows minus **4** dropped orphan
*copies*. (Correction to an earlier figure of 350: §3.2 lists **3 distinct keys**, but `Other` exists in
**three** catalogs — `app`, `domain`, `onboarding` — so it contributes **two** dropped copies, not one.
4 copies of 3 keys.) `ro.json` has **335**: the same 349, minus the 10 keys no catalog translates, minus
the **4** Class-B/F dead translations whose RO is stripped (§3.4), plus `Cancel`'s hand-authored override.

### These files are GENERATED — do not hand-edit

`Web/gen-locales.py` emits both bundles from the five catalogs.

```
python3 Web/gen-locales.py            # regenerate
python3 Web/gen-locales.py --check    # exit 1 if the committed files are stale (CI-friendly)
```

It implements every rule in this document: namespacing (§2), EN-falls-back-to-key, RO omitted when
absent so `i18n.ts` warns rather than guessing, and the §3.2 orphan drop. It also **preserves
hand-authored Romanian** for the keys no catalog translates (§4) — currently just
`app.Cancel = "Anulează"` — and reports each override it kept, so a deliberate human translation is
never silently clobbered by a regeneration.

Hand-transcribing 349 strings is exactly where a plausible-but-wrong Romanian value would enter, which
is the whole reason this is a script and not a task.

**Why the EN column is lower than Keys:** a catalog entry with no explicit `en` localization falls
back to the key itself, which *is* the English text. The **Expenses** catalog has **zero** `en`
entries — its English comes entirely from the Swift literals. So EN coverage is effectively 100 %;
the gap that matters is RO: **11 keys have no Romanian** (§4).

---

## 2. Bundle resolution — why namespacing is mandatory

On iOS a string resolves against **the bundle of the module that renders it**. `"Primary"` in the
Settings sheet reads the `app` catalog; the same literal in `AccountRow` reads the `onboarding`
catalog. Five modules therefore form five independent key spaces that happen to overlap.

**39 keys appear in more than one catalog** — see §3. A flat union would pick one arbitrarily
and silently change text on some screens.

### Recommended web layout

```
Web/Client/src/locales/
  en.json   { "app": {...}, "domain": {...}, "onboarding": {...},
              "dashboard": {...}, "expenses": {...} }
  ro.json   same five top-level namespaces
```
Look-ups are `t('<namespace>.<exact English literal>')`. Keep the literal verbatim as the key —
including punctuation, `×`, `→`, `—` and trailing `...` — so it stays greppable against the Swift source.

**Namespace to use per screen:**

| Screen / component | Namespace |
|---|---|
| Tab bar labels, Insights placeholder, New Month accessory button | `app` |
| Settings sheet, AccountEditorSheet | `app` |
| All 7 onboarding screens + AccountRow, AddAccountSheet, SavingsSlider, RemainingMoneyPicker, EmergencyMultiplierPicker, ExpenseRow | `onboarding` |
| Dashboard cards (Summary, EmergencyProgress, AccountBalances, ExpenseBreakdown) | `dashboard` |
| New Month flow (all 3 steps) | `dashboard` |
| Expenses tab, AddExpenseSheet, CategoryManagementView, AddCategorySheet, ExpenseItemRow, ExpenseCategoryCard, FrequencyPicker, CategoryPicker | `expenses` |
| Any enum display name / description (AccountType, Frequency, AllocationMode, SavingsInputMode, RemainingMoneyDestination) **wherever rendered** | `domain` |

> The last row is the subtle one: enum labels always come from `domain`, even when shown on an
> `expenses` or `app` screen, because `displayName` is computed inside the Domain module. The namespace
> follows **where the string is defined in Swift**, not which screen renders it.
>
> ⚠️ **Exception — declaration shadowing.** A file-private extension can shadow a Domain property for
> that file only, so the *same* symbol yields a different string per screen. `SettingsSheet.swift:698-706`
> redeclares `RemainingMoneyDestination.displayName`, making `.primary` read **"Primary Account"**
> (`app`, `Cont principal`) in Settings but **"Keep in Primary"** (`domain`,
> `Păstrează în Principal`) in onboarding. Both translate — this is two correct labels, not leakage.
> So Standing rule #3 has a fourth clause: check **which declaration the symbol resolves to**.
> Full register: `PARITY-REGISTER.md §B1`.

### ⚖️ Which served `displayName`s to translate — and which to leave in English

Every `*DisplayName` field in an API response is an **English lookup key**, never ready-to-render text
(`DOMAIN-CONTRACT.md §1`: SwiftPM does not compile `.xcstrings`, so server-side `.localized` always
returns the key). But **"translate them all" is wrong** — two of the six enums show English on iOS too,
so translating those would be a *silent improvement*, which R26a forbids.

| Enum `displayName` | Domain catalog RO | On iOS in RO | Web must |
|---|---|---|---|
| `AccountType` — Primary, Emergency, Savings, Personal, Joint, Other | 6/6 | **Romanian** | ✅ translate via `tDomain` |
| `AllocationMode` — Priority, Split | 2/2 | **Romanian** | ✅ translate via `tDomain` |
| `SavingsInputMode` — Percentage, Fixed Amount | 2/2 | **Romanian** | ✅ translate via `tDomain` |
| `RemainingMoneyDestination` — Primary Savings, Personal Account, Keep in Primary | 3/3 | **Romanian** | ✅ translate via `tDomain` |
| **`Frequency`** — Monthly, Annual | **0/2** | **English** | ⛔ **render raw** |
| **`Currency`** — Romanian Leu (RON), Euro (EUR), US Dollar (USD) | **0/3** | **English** | ⛔ **render raw** |

Why the two exceptions:

- **`Frequency`** — `Frequency.displayName` is Domain code binding **Domain's** bundle, and `Monthly` /
  `Annual` are absent from Domain's catalog. The `Monthly → "Lunar"` and `Annual → "Anual"` entries live
  in the **`expenses`** catalog, which `displayName` never reads. So iOS renders `Monthly` / `Annual`
  untranslated — in the Expenses segmented control *and* in the header. See `PARITY-SPEC.md §5.1`.
  ⚠️ **`expenses.Annual` = "Anual" is still live**, but only for `ExpenseItemRow.swift:60`'s `(Annual)`
  caption, which binds the Expenses bundle. So `(Anual)` under a segment reading `Annual` is correct.
- **`Currency`** — `Currency.displayName` (`Utilities/Currency.swift:19-25`) has **no `.localized` call
  at all**; it returns bare Swift literals. It is untranslated on every platform by construction.

### ⚖️ Ruling on the `→ app → key` fallback chain

Frontend implemented lookup order **requested-ns → `app` → key**. That is **sound as a safety net, with
one carve-out**:

- ✅ **Safe for the 36 keys in §3.3** — identical in every catalog, so a fallback cannot change text.
- ✅ **Safe for the 259 single-catalog keys** — no ambiguity to resolve.
- ⛔ **Must NOT be able to reach the 3 keys in §3.2.** Each has exactly one live render path, in
  `domain`. If a component requests a namespace that lacks the key and falls through to `app`,
  `Other` resolves to **"Altele"** where iOS shows **"Altul"** — a wrong string, silently, in Romanian
  only, on a screen that looks fine in English.

**Concrete fix, cheapest first:** drop the orphaned copies when building the bundles — emit
`Other`, `For building wealth over time` and `Receives savings after emergency` **only** under `domain`.
Then the fallback chain is provably safe as written, because there is nothing wrong left for it to find.

Two hardening suggestions, both cheap:
1. **Log every fallback in dev.** A fallback firing means a component asked for the wrong namespace —
   that is a bug worth surfacing while it is cheap, not a condition to absorb silently.
2. **Enum-derived values should request `domain` explicitly**, not the screen's namespace. In practice
   the server sends these pre-resolved (R2/R12), so the client may not look them up at all — in which
   case this reduces to "make sure the server reads them from `domain`".

---

## 3. Cross-catalog collisions — 39 shared keys

- **0** with conflicting English → *(none — English is consistent everywhere)*
- **3** with identical English but **conflicting Romanian** → §3.2, **must be preserved**
- **36** identical in every catalog → §3.3, safe to duplicate

### 3.2 ⚠️ Same English, DIFFERENT Romanian — but only ONE copy is ever read

> 🔁 **Correction to my earlier guidance.** I first reported these as "real behavioural differences —
> collapsing them changes on-screen text". That was inferred from the catalog data alone and is **wrong**.
> Tracing the render sites shows each of the three has **exactly one Swift literal, and all three are in
> Domain**, so at runtime only Domain's Romanian is ever displayed. The `app` / `onboarding` copies are
> **orphaned duplicates** — almost certainly left behind by Xcode string extraction when this code lived
> in those modules before the SPM split. Verified: the literal `"Other"` does not appear anywhere in the
> app target's Swift at all.
>
> | Key | Only Swift literal | Renders as (RO) | Orphaned copies |
> |---|---|---|---|
> | `Other` | `AccountType.swift:29` (`.other.displayName`) | **"Altul"** | `app` "Altele" — **never read** |
> | `For building wealth over time` | `AccountEntry.swift:120` (`.savings()` purpose) | **"Pentru a construi avere în timp"** | `onboarding` variant — never read |
> | `Receives savings after emergency` | `AccountType.swift:49` (`.savings.description`) | **"Primește economii după fondul de urgență"** | `onboarding` variant — never read |
>
> **What this means for the web:** do **not** preserve the divergence — preserve the *winner*. Put these
> three only in the `domain` namespace with the values above, and **omit the orphaned copies entirely**.
> Shipping `app.Other = "Altele"` creates a string that iOS can never display, and any fallback chain
> that can reach it will render text the real app does not.
>
> ⚠️ **Consequence for a `→ app → key` fallback chain:** it is safe for the 36 identical keys in §3.3,
> but for these three it can silently substitute the losing translation. Enum- and factory-derived
> strings must resolve in `domain`; see the ruling at the end of §2.

Raw catalog data for the three, for reference:

| Key (EN) | Namespace | Romanian |
|---|---|---|
| `For building wealth over time` | `domain` | Pentru a construi avere în timp |
|  | `onboarding` | Pentru a economisi pe termen lung |
| `Other` | `app` | Altele |
|  | `domain` | Altul |
|  | `onboarding` | Altul |
| `Receives savings after emergency` | `domain` | Primește economii după fondul de urgență |
|  | `onboarding` | Primește economii după urgență |

Concretely: `AccountType.other.displayName` resolves in `domain` → **"Altul"**, but the standalone
`"Other"` literal in the Settings currency/type rows resolves in `app` → **"Altele"**. Both ship.

### 3.4 Systematic orphan sweep — all 353 rows classified

Deliberate pass over every catalog row, resolving each against its possible Swift call sites.
**The rule that makes this necessary:** `.localized` names a *lookup*, not a translation.
Whether it resolves depends on **which bundle the call site binds** *and* **whether that catalog
holds the key**. Three call forms behave differently:

| Form | Runtime key | Reachable with a `%@` catalog key? |
|---|---|---|
| `"literal".localized` | the literal | n/a — no placeholders |
| `"a \(x) b".localized` | **the interpolated string** — interpolation happens *before* `.localized` | ❌ **no** — the catalog's `a %@ b` can never match |
| `String(localized: "a \(x) b", bundle:)` / `String.localized("a \(x) b")` | `a %@ b` — `LocalizationValue` captures the placeholders | ✅ yes |

**Result: 271 of 352 non-empty rows verified reachable; 81 unreachable** (74 of those still carry a
Romanian value, which is what makes them misleading rather than merely dead).

#### ⚠️ What 271/81 does and does not establish — the instrument's blind spot

**It establishes:** for each catalog row, whether *a* Swift call site exists in the owning module that
could produce a key of that shape. That is enough to identify dead rows (Classes D, E) and
wrong-bundle copies (Classes A, B, C).

**It does NOT establish that the exact variant of a format key is the live one.** When matching a call
site the sweep normalises `%@`, `%lld` and `%d` to a single `%`, so
`Step %lld of %lld` and `Step %d of %d` are indistinguishable to it — both are reported reachable
because *one* of them is. Resolving which requires the **Swift type** at the interpolation:
`Int` emits **`%lld`**, `String` emits **`%@`**, `Double` emits `%lf`.

**Consequence:** any catalog row whose key contains a format specifier carries residual uncertainty
that this sweep cannot remove. Class F exists *because* G7 forced that determination by hand, and
Class F is the only class found by reading types rather than by running the tool. **If a `%`-keyed
string renders wrongly, re-derive its variant from the Swift type before trusting the table above.**

Two further notes on the tooling, so the numbers are read with the right confidence:

- The sweep scans each file **whole**, not line-by-line, because the call form spans lines:
  `String(` … `localized: "…",` … `bundle: .module` … `)`. A line-oriented scanner cannot see it. An
  earlier line-based version wrongly flagged **5 live keys** as unreachable, including
  `dashboard.'was %@ last month'` and both G7 keys. That is the specific lesson: **line-oriented tools
  cannot see a call form that spans lines.**
- Two other false-positive classes were found and fixed before publication: a `[^)]*` pattern that
  broke on nested parens inside an interpolation, and non-interpolated `String(localized:)` calls
  landing in the *captured* set while only the *plain* set was consulted. The counts here are
  post-correction. Given four self-caught tooling issues, treat a single-pass result from this script as
  **provisional until its counter-case is checked**.

- **Every widening of a scanner admits a new false-positive class**, so a widening must always be
  paired with a re-check of what the new surface lets in. Concretely: the client-side glyph sweep was
  first scoped to `t()` arguments, which structurally could not see the same bad string sitting in
  plain JSX (`Gallery.tsx`). Widening it to *every* quoted literal found that — and simultaneously
  started matching prose inside doc comments, producing a false hit on `viewState.ts`'s
  `'New Category…'`, which is documentation, not UI. Fix: strip block and line comments before
  matching. The general shape is that each new surface brings its own non-UI text, so the yield of a
  widening should be reported as *(real / confirmed / newly-admitted noise)* rather than as a count.

| Class | Count | Meaning | Action |
|---|---|---|---|
| **A — wrong Romanian** | **3** | copy's RO differs from the producing module's RO | 🔴 **dropped** from the bundles |
| **B — Romanian where English is correct** | **2** | copy has RO, but the *producing* module's catalog has no entry, so iOS falls back to English | 🔴 **RO dropped**, EN kept |
| **C — benign duplicate** | 21 | identical RO in both catalogs | 🟢 harmless; keep or drop |
| **D — dead interpolated** | 1 | `%@` key that `"...".localized` can never produce | 🟡 dead; do not wire up |
| **E — no call site at all** | ~55 | literal appears in no Swift source — stale keys from removed code | 🟡 dead; harmless |
| **F — variant mismatch** | **2 pairs** | a re-extraction left a *translated* stale variant beside an *untranslated* live one | 🔴 stale RO **dropped** |

#### Class A — wrong Romanian (dropped)

| Key | Orphan copy | What iOS actually renders |
|---|---|---|
| `Other` | `app` = "Altele" | `domain` = **"Altul"** |
| `For building wealth over time` | `onboarding` = "Pentru a economisi pe termen lung" | `domain` = **"Pentru a construi avere în timp"** |
| `Receives savings after emergency` | `onboarding` = "Primește economii după urgență" | `domain` = **"Primește economii după fondul de urgență"** |

The sweep found **exactly** the three already known — a useful negative result: there are no further
wrong-Romanian orphans hiding.

#### Class B — Romanian where English is correct (RO dropped) — NEW

| Key | Copy with RO | Producing call site | Why iOS shows English |
|---|---|---|---|
| `Monthly` | `expenses` = "Lunar" | Domain `Frequency.displayName` → `"Monthly".localized`, binds **Domain**'s bundle | Domain's catalog has **no** `Monthly` |
| `Amount` | `expenses` = "Sumă" | SharedUI `String(localized: "Amount")` — **no `bundle:`**, so binds `.main` | the app catalog has **no** `Amount` |

These are the more insidious direction: shipping them renders **Romanian where iOS shows English**, i.e.
a silent improvement, which R26a forbids. This is the same hazard that nearly reached the code as
"translate `Monthly` to Lunar".

⚠️ **`expenses.Annual` = "Anual" is deliberately NOT dropped.** Unlike `Monthly`, it has a genuine call
site inside the Expenses module — `ExpenseItemRow.swift:60`'s `"Annual".localized` for the `(Annual)`
caption, which binds the Expenses bundle. So `(Anual)` is correct there, sitting under a segmented
control that still reads `Annual`. Reproduce that inconsistency.

#### Class D — dead interpolated

`expenses.'Total %@ Expenses'` = "Cheltuieli %@ totale". Xcode's static extractor wrote the `%@` form
from the *source* interpolation, but `ExpenseListView.swift:91` uses `"...".localized`, so the runtime
key is the filled string. See `PARITY-SPEC.md §5.1`.

#### Class E — no call site (60 rows, all dead)

Stale keys left by removed code, all still carrying Romanian. A representative sample shows they come
from an earlier design: `Add Subcategory`, `Default Subcategories`, `Custom Subcategories`,
`New Subcategory`, `subcategories`, `Main Checking`, `Checking`, `Almost there!`, `Your Goals`,
`Goal complete this month!`, `How much to save?`, `Let's build your savings plan`, `No limit`,
`Target multiplier`, `Stays in Main`, `Tap to add`. Spot-checked by grepping the whole repo: 0 Swift
files contain them. Harmless — nothing can request them — but they inflate the catalogs by ~17 %, and
they are why a raw catalog row-count overstates what the app can display.

**Regenerating is what enforces all of this** — the drop lists live in `Web/gen-locales.py`, and
`--check` is a required CI step (R27).

### 3.3 Identical across catalogs — duplicate freely

| Key | Namespaces |
|---|---|
| `%lld%%` | `app`, `dashboard` |
| `Account Name` | `app`, `onboarding` |
| `Add` | `onboarding`, `expenses` |
| `Add to your savings for future goals` | `domain`, `onboarding` |
| `Cancel` | `app`, `onboarding`, `dashboard`, `expenses` |
| `Caps the emergency fund target at a fixed amount` | `app`, `onboarding` |
| `Continue` | `onboarding`, `dashboard` |
| `Current balance` | `onboarding`, `dashboard` |
| `Custom account` | `domain`, `onboarding` |
| `Emergency` | `app`, `domain`, `onboarding` |
| `Emergency Fund` | `domain`, `onboarding`, `dashboard` |
| `Expenses` | `app`, `dashboard`, `expenses` |
| `Fills first until target reached` | `domain`, `onboarding` |
| `Financial experts recommend saving 20-30% of your income` | `domain`, `onboarding` |
| `For flexible spending` | `domain`, `onboarding` |
| `For shared expenses` | `domain`, `onboarding` |
| `Joint` | `app`, `domain`, `onboarding` |
| `Keep in Primary` | `domain`, `onboarding` |
| `Leave in your main account` | `domain`, `onboarding` |
| `Main Account` | `domain`, `onboarding` |
| `Maximum amount` | `app`, `onboarding` |
| `Monthly Savings` | `app`, `onboarding` |
| `Name` | `app`, `expenses` |
| `New Month` | `app`, `dashboard` |
| `Personal` | `app`, `domain`, `onboarding`, `dashboard` |
| `Personal Account` | `app`, `domain`, `onboarding` |
| `Primary` | `app`, `domain`, `onboarding`, `dashboard`, `expenses` |
| `Primary Savings` | `app`, `domain`, `onboarding` |
| `Protects you from unexpected expenses` | `domain`, `onboarding` |
| `Remaining Money` | `app`, `onboarding` |
| `Save` | `app`, `expenses` |
| `Savings` | `app`, `domain`, `onboarding`, `dashboard` |
| `Savings Boost` | `app`, `onboarding` |
| `Where your salary lands` | `domain`, `onboarding` |
| `Your flexible spending money` | `domain`, `onboarding` |
| `Your name` | `app`, `onboarding` |

---

## 4. Keys with no Romanian (11) — these fall back to English

| Namespace | Key |
|---|---|
| `app` | `%lld%%` |
| `app` | `0` |
| `app` | `2×` |
| `app` | `3×` |
| `app` | `Cancel` |
| `dashboard` | `%lld%%` |
| `dashboard` | `+%@` |
| `dashboard` | `Step %lld of %lld` |
| `dashboard` | `Target: %lld× monthly income` |
| `expenses` | `` |
| `expenses` | `(%@)` |

Mostly format scaffolding (`%lld%%`, `0`, `2×`, `3×`) plus a few genuine gaps. `Cancel` having no RO
in the `app` catalog is harmless — iOS supplies a system translation for toolbar roles, but **the web
must translate it explicitly**.

---

## 5. Full inventory per catalog

`_(= key)_` in the EN column means no explicit `en` entry — the key itself is the English text.
`state` is the catalog's own translation state for RO.


### 5.1 `app` — Main app target

Path: `Diameris/Resources/Localizable.xcstrings`  
Bundle: `.main` · 59 keys · 54 explicit EN · 54 RO

| Key (EN source string) | EN | RO | RO state |
|---|---|---|---|
| `%lld%%` | _(= key)_ | **MISSING** | — |
| `0` | _(= key)_ | **MISSING** | — |
| `2×` | _(= key)_ | **MISSING** | — |
| `3×` | _(= key)_ | **MISSING** | — |
| `Account Name` | Account Name | Nume cont | translated |
| `Account Type` | Account Type | Tip cont | translated |
| `Accounts` | Accounts | Conturi | translated |
| `Allocation Mode` | Allocation Mode | Mod de alocare | translated |
| `Balance` | Balance | Sold | translated |
| `Boost Multiplier` | Boost Multiplier | Multiplicator boost | translated |
| `Cancel` | _(= key)_ | **MISSING** | — |
| `Caps the emergency fund target at a fixed amount` | Caps the emergency fund target at a fixed amount | Limitează ținta fondului de urgență la o sumă fixă | translated |
| `Coming soon` | Coming soon | În curând | translated |
| `Currency` | Currency | Monedă | translated |
| `Current Balance` | Current Balance | Sold curent | translated |
| `Dashboard` | Dashboard | Panou | translated |
| `Destination` | Destination | Destinație | translated |
| `Edit Account` | Edit Account | Editare cont | translated |
| `Effective Rate` | Effective Rate | Rată efectivă | translated |
| `Emergency` | Emergency | Urgență | translated |
| `Emergency Fund Target` | Emergency Fund Target | Țintă fond de urgență | translated |
| `Expenses` | Expenses | Cheltuieli | translated |
| `Insights` | Insights | Analize | translated |
| `Joint` | Joint | Comun | translated |
| `Maximum` | Maximum | Maxim | translated |
| `Maximum amount` | Maximum amount | Suma maximă | translated |
| `Monthly Savings` | Monthly Savings | Economii lunare | translated |
| `Name` | Name | Nume | translated |
| `New Month` | New Month | Lună nouă | translated |
| `Other` | Other | Altele | translated |
| `Personal` | Personal | Personal | translated |
| `Personal Account` | Personal Account | Cont personal | translated |
| `Primary` | Primary | Principal | translated |
| `Primary Account` | Primary Account | Cont principal | translated |
| `Primary Savings` | Primary Savings | Economii principale | translated |
| `Primary Savings Account` | Primary Savings Account | Cont principal de economii | translated |
| `Profile` | Profile | Profil | translated |
| `Remaining Money` | Remaining Money | Bani rămași | translated |
| `Save` | Save | Salvează | translated |
| `Savings` | Savings | Economii | translated |
| `Savings Boost` | Savings Boost | Boost economii | translated |
| `Savings Rate` | Savings Rate | Rată economii | translated |
| `Savings Type` | Savings Type | Tip economii | translated |
| `Savings are calculated from income after expenses.` | Savings are calculated from income after expenses. | Economiile se calculează din venitul rămas după cheltuieli. | translated |
| `Set maximum amount` | Set maximum amount | Setează suma maximă | translated |
| `Settings` | Settings | Setări | translated |
| `Tap an account to edit its settings.` | Tap an account to edit its settings. | Atinge un cont pentru a-i edita setările. | translated |
| `Target` | Target | Țintă | translated |
| `Target Amount` | Target Amount | Sumă țintă | translated |
| `The fund target will be capped at this amount regardless of income multiplier.` | The fund target will be capped at this amount regardless of income multiplier. | Ținta fondului va fi limitată la această sumă indiferent de multiplicatorul de venit. | translated |
| `The primary savings account receives automatic savings allocation.` | The primary savings account receives automatic savings allocation. | Contul principal de economii primește alocarea automată a economiilor. | translated |
| `Total Monthly` | Total Monthly | Total lunar | translated |
| `Total exceeds available income. Amounts will be reduced proportionally.` | Total exceeds available income. Amounts will be reduced proportionally. | Totalul depășește venitul disponibil. Sumele vor fi reduse proporțional. | translated |
| `Type` | Type | Tip | translated |
| `Where leftover money goes after savings allocation.` | Where leftover money goes after savings allocation. | Unde merg banii rămași după alocarea economiilor. | translated |
| `Your name` | Your name | Numele tău | translated |
| `income` | income | venit | translated |
| `max` | max | max | translated |
| `monthly income` | monthly income | venit lunar | translated |

### 5.2 `domain` — Core/Domain

Path: `Packages/Core/Domain/Sources/Domain/Resources/Localizable.xcstrings`  
Bundle: `.module` (Domain) · 29 keys · 29 explicit EN · 29 RO

| Key (EN source string) | EN | RO | RO state |
|---|---|---|---|
| `Add to your savings for future goals` | Add to your savings for future goals | Adaugă la economii pentru obiective viitoare | translated |
| `Custom account` | Custom account | Cont personalizat | translated |
| `Emergency` | Emergency | Urgență | translated |
| `Emergency Fund` | Emergency Fund | Fond de urgență | translated |
| `Emergency fund fills first, then savings` | Emergency fund fills first, then savings | Fondul de urgență se completează primul, apoi economiile | translated |
| `Fills first until target reached` | Fills first until target reached | Se completează primul până la țintă | translated |
| `Financial experts recommend saving 20-30% of your income` | Financial experts recommend saving 20-30% of your income | Experții financiari recomandă economisirea a 20-30% din venit | translated |
| `Fixed Amount` | Fixed Amount | Sumă fixă | translated |
| `Fixed amounts to each account every month` | Fixed amounts to each account every month | Sume fixe către fiecare cont în fiecare lună | translated |
| `For building wealth over time` | For building wealth over time | Pentru a construi avere în timp | translated |
| `For flexible spending` | For flexible spending | Pentru cheltuieli flexibile | translated |
| `For shared expenses` | For shared expenses | Pentru cheltuieli comune | translated |
| `Joint` | Joint | Comun | translated |
| `Keep in Primary` | Keep in Primary | Păstrează în Principal | translated |
| `Leave in your main account` | Leave in your main account | Lasă în contul principal | translated |
| `Main Account` | Main Account | Cont principal | translated |
| `Other` | Other | Altul | translated |
| `Percentage` | Percentage | Procent | translated |
| `Personal` | Personal | Personal | translated |
| `Personal Account` | Personal Account | Cont personal | translated |
| `Primary` | Primary | Principal | translated |
| `Primary Savings` | Primary Savings | Economii principale | translated |
| `Priority` | Priority | Prioritizat | translated |
| `Protects you from unexpected expenses` | Protects you from unexpected expenses | Te protejează de cheltuieli neașteptate | translated |
| `Receives savings after emergency` | Receives savings after emergency | Primește economii după fondul de urgență | translated |
| `Savings` | Savings | Economii | translated |
| `Split` | Split | Separat | translated |
| `Where your salary lands` | Where your salary lands | Unde îți intră salariul | translated |
| `Your flexible spending money` | Your flexible spending money | Banii tăi pentru cheltuieli flexibile | translated |

### 5.3 `onboarding` — Features/Onboarding

Path: `Packages/Features/Onboarding/Sources/Onboarding/Resources/Localizable.xcstrings`  
Bundle: `.module` (Onboarding) · 169 keys · 169 explicit EN · 169 RO

| Key (EN source string) | EN | RO | RO state |
|---|---|---|---|
| `%@ amount` | %@ amount | Suma %@ | translated |
| `%lld percent, %@ per month` | %lld percent, %@ per month | %lld procente, %@ pe lună | translated |
| `%lld times income` | %lld times income | %lld ori venitul | translated |
| `%lldx income (%@)` | %lldx income (%@) | %lldx venit (%@) | translated |
| `25% recommended` | 25% recommended | 25% recomandat | translated |
| `A quick look at your main expenses. Don't worry about being exact — estimates are fine.` | A quick look at your main expenses. Don't worry about being exact — estimates are fine. | O privire rapidă asupra cheltuielilor principale. Nu trebuie să fii exact — estimările sunt suficiente. | translated |
| `Account Name` | Account Name | Nume cont | translated |
| `Account name` | Account name | Nume cont | translated |
| `Account type` | Account type | Tip cont | translated |
| `Add` | Add | Adaugă | translated |
| `Add Account` | Add Account | Adaugă cont | translated |
| `Add Another Account` | Add Another Account | Adaugă alt cont | translated |
| `Add an emergency or savings account first to use split mode.` | Add an emergency or savings account first to use split mode. | Adaugă mai întâi un cont de urgență sau de economii pentru a folosi modul separat. | translated |
| `Add to your savings for future goals` | Add to your savings for future goals | Adaugă la economii pentru obiective viitoare | translated |
| `After expenses` | After expenses | După cheltuieli | translated |
| `All accounted for!` | All accounted for! | Totul este contabilizat! | translated |
| `Allocation Strategy` | Allocation Strategy | Strategie de alocare | translated |
| `Almost there!` | Almost there! | Aproape am terminat! | translated |
| `Already saved:` | Already saved: | Deja economisit: | translated |
| `Auto-Save` | Auto-Save | Economisire automată | translated |
| `Available after savings` | Available after savings | Disponibil după economii | translated |
| `Based on income` | Based on income | Pe baza venitului | translated |
| `Boost is great for catching up, but not sustainable long-term` | Boost is great for catching up, but not sustainable long-term | Boost-ul e bun pentru recuperare, dar nu e sustenabil pe termen lung | translated |
| `Build wealth over time. After emergency fund is full, savings go here.` | Build wealth over time. After emergency fund is full, savings go here. | Economisește pe termen lung. După ce fondul de urgență e plin, economiile vin aici. | translated |
| `By default, expenses are paid from your main account` | By default, expenses are paid from your main account | Implicit, cheltuielile se plătesc din contul principal | translated |
| `Cancel` | Cancel | Anulează | translated |
| `Caps the emergency fund target at a fixed amount` | Caps the emergency fund target at a fixed amount | Limitează ținta fondului de urgență la o sumă fixă | translated |
| `Checking` | Checking | Cont curent | translated |
| `Complete` | Complete | Complet | translated |
| `Continue` | Continue | Continuă | translated |
| `Continues to the accounts step` | Continues to the accounts step | Continuă la pasul conturilor | translated |
| `Continues to the expenses step` | Continues to the expenses step | Continuă la pasul cheltuielilor | translated |
| `Continues to the next step` | Continues to the next step | Continuă la pasul următor | translated |
| `Current balance` | Current balance | Sold curent | translated |
| `Current:` | Current: | Actual: | translated |
| `Custom account` | Custom account | Cont personalizat | translated |
| `Emergency` | Emergency | Urgență | translated |
| `Emergency Fund` | Emergency Fund | Fond de urgență | translated |
| `Emergency fund fills first until target reached` | Emergency fund fills first until target reached | Fondul de urgență se completează primul până la țintă | translated |
| `Emergency fund fills first, then regular savings` | Emergency fund fills first, then regular savings | Fondul de urgență se completează primul, apoi economiile regulate | translated |
| `Enhanced protection` | Enhanced protection | Protecție îmbunătățită | translated |
| `Expense categories` | Expense categories | Categorii de cheltuieli | translated |
| `Fills first until target reached` | Fills first until target reached | Se completează primul până la țintă | translated |
| `Financial experts recommend saving 20-30% of your income` | Financial experts recommend saving 20-30% of your income | Experții financiari recomandă economisirea a 20-30% din venit | translated |
| `First, let's get acquainted` | First, let's get acquainted | Mai întâi, să ne cunoaștem | translated |
| `Fixed amount` | Fixed amount | Sumă fixă | translated |
| `Fixed amount to emergency each month` | Fixed amount to emergency each month | Sumă fixă către urgență în fiecare lună | translated |
| `Fixed amount to savings each month` | Fixed amount to savings each month | Sumă fixă către economii în fiecare lună | translated |
| `Flexible spending money` | Flexible spending money | Bani pentru cheltuieli flexibile | translated |
| `Food & Groceries` | Food & Groceries | Mâncare și cumpărături | translated |
| `For automatic bill payments` | For automatic bill payments | Pentru plăți automate de facturi | translated |
| `For automatic payments` | For automatic payments | Pentru plăți automate | translated |
| `For building wealth over time` | For building wealth over time | Pentru a economisi pe termen lung | translated |
| `For flexible spending` | For flexible spending | Pentru cheltuieli flexibile | translated |
| `For shared expenses` | For shared expenses | Pentru cheltuieli comune | translated |
| `For your savings goals` | For your savings goals | Pentru obiectivele tale de economii | translated |
| `From:` | From: | Din: | translated |
| `Goal complete this month!` | Goal complete this month! | Obiectiv îndeplinit luna aceasta! | translated |
| `Great savings rate!` | Great savings rate! | Rată excelentă de economii! | translated |
| `Here's your personalized transfer plan, %@!` | Here's your personalized transfer plan, %@! | Iată planul tău personalizat de transferuri, %@! | translated |
| `How much do you want to save?` | How much do you want to save? | Cât vrei să economisești? | translated |
| `How much lands in your account each month after taxes?` | How much lands in your account each month after taxes? | Cât intră în contul tău în fiecare lună, după taxe? | translated |
| `How much to save?` | How much to save? | Cât să economisești? | translated |
| `How your savings are distributed` | How your savings are distributed | Cum sunt distribuite economiile tale | translated |
| `In the next few minutes, we'll build your personalized transfer plan — so payday becomes effortless.` | In the next few minutes, we'll build your personalized transfer plan — so payday becomes effortless. | În următoarele minute, vom construi planul tău personalizat de transferuri — ca ziua de salariu să devină fără efort. | translated |
| `Joint` | Joint | Comun | translated |
| `Keep in Primary` | Keep in Primary | Păstrează în Principal | translated |
| `Keep saving with no upper limit` | Keep saving with no upper limit | Continuă să economisești fără limită superioară | translated |
| `Know exactly where to transfer your money` | Know exactly where to transfer your money | Știi exact unde să transferi banii | translated |
| `Leave in your main account` | Leave in your main account | Lasă în contul principal | translated |
| `Let's Go` | Let's Go | Hai să începem | translated |
| `Let's build your savings plan` | Let's build your savings plan | Să construim planul tău de economii | translated |
| `Link expenses (optional)` | Link expenses (optional) | Leagă cheltuieli (opțional) | translated |
| `Lower your savings rate to enable boost` | Lower your savings rate to enable boost | Scade rata de economii pentru a activa boost-ul | translated |
| `Main` | Main | Principal | translated |
| `Main Account` | Main Account | Cont principal | translated |
| `Main Checking` | Main Checking | Cont principal | translated |
| `Max:` | Max: | Max: | translated |
| `Maximum amount` | Maximum amount | Suma maximă | translated |
| `Maximum security` | Maximum security | Securitate maximă | translated |
| `Minimum recommended` | Minimum recommended | Minim recomandat | translated |
| `Monthly Amounts` | Monthly Amounts | Sume lunare | translated |
| `Monthly Income` | Monthly Income | Venit lunar | translated |
| `Monthly Savings` | Monthly Savings | Economii lunare | translated |
| `Monthly income amount` | Monthly income amount | Suma venitului lunar | translated |
| `Monthly net income` | Monthly net income | Venit lunar net | translated |
| `Monthly savings amount` | Monthly savings amount | Suma lunară de economii | translated |
| `Monthly to emergency` | Monthly to emergency | Lunar către urgență | translated |
| `Monthly to savings` | Monthly to savings | Lunar către economii | translated |
| `Nice to meet you, %@!` | Nice to meet you, %@! | Încântat de cunoștință, %@! | translated |
| `No limit` | No limit | Fără limită | translated |
| `No limit - keep saving!` | No limit - keep saving! | Fără limită - continuă să economisești! | translated |
| `No target limit` | No target limit | Fără limită țintă | translated |
| `Only one emergency account allowed` | Only one emergency account allowed | Este permis un singur cont de urgență | translated |
| `Opens a sheet to add a new account` | Opens a sheet to add a new account | Deschide un ecran pentru a adăuga un cont nou | translated |
| `Other` | Other | Altul | translated |
| `Percentage of income to emergency each month` | Percentage of income to emergency each month | Procent din venit către urgență în fiecare lună | translated |
| `Percentage of income to savings each month` | Percentage of income to savings each month | Procent din venit către economii în fiecare lună | translated |
| `Personal` | Personal | Personal | translated |
| `Personal Account` | Personal Account | Cont personal | translated |
| `Primary` | Primary | Principal | translated |
| `Primary Savings` | Primary Savings | Economii principale | translated |
| `Progress` | Progress | Progres | translated |
| `Protects you from unexpected expenses` | Protects you from unexpected expenses | Te protejează de cheltuieli neașteptate | translated |
| `Protects you from unexpected expenses. Recommended: 3-6 months of income.` | Protects you from unexpected expenses. Recommended: 3-6 months of income. | Te protejează de cheltuieli neașteptate. Recomandat: 3-6 luni de venit. | translated |
| `Quick suggestions` | Quick suggestions | Sugestii rapide | translated |
| `Receives savings after emergency` | Receives savings after emergency | Primește economii după urgență | translated |
| `Recommended` | Recommended | Recomandat | translated |
| `Remaining Money` | Remaining Money | Bani rămași | translated |
| `Remaining savings go to your savings account` | Remaining savings go to your savings account | Economiile rămase merg în contul de economii | translated |
| `Remove %@` | Remove %@ | Șterge %@ | translated |
| `Rent / Housing` | Rent / Housing | Chirie / Locuință | translated |
| `Salary` | Salary | Salariu | translated |
| `Saved: %@` | Saved: %@ | Economisit: %@ | translated |
| `Savings` | Savings | Economii | translated |
| `Savings Account` | Savings Account | Cont de economii | translated |
| `Savings Boost` | Savings Boost | Boost economii | translated |
| `Savings are calculated from your income after expenses.` | Savings are calculated from your income after expenses. | Economiile sunt calculate din venitul tău după cheltuieli. | translated |
| `Savings percentage` | Savings percentage | Procentaj economii | translated |
| `Set as Primary Savings` | Set as Primary Savings | Setează ca economii principale | translated |
| `Set maximum` | Set maximum | Setează maxim | translated |
| `Set savings goals that fill automatically` | Set savings goals that fill automatically | Setează obiective de economii care se completează automat | translated |
| `Set up your accounts. We recommend an emergency fund and savings account.` | Set up your accounts. We recommend an emergency fund and savings account. | Configurează-ți conturile. Recomandăm un fond de urgență și un cont de economii. | translated |
| `Shared expenses` | Shared expenses | Cheltuieli comune | translated |
| `Shared with someone else` | Shared with someone else | Împărțit cu altcineva | translated |
| `Skip for now` | Skip for now | Sari peste pentru moment | translated |
| `Skips expense entry and continues` | Skips expense entry and continues | Sare peste introducerea cheltuielilor și continuă | translated |
| `Standard protection` | Standard protection | Protecție standard | translated |
| `Start Using Diameris` | Start Using Diameris | Începe să folosești Diameris | translated |
| `Stays in Main` | Stays in Main | Rămâne în Principal | translated |
| `Stays in Primary` | Stays in Primary | Rămâne în Principal | translated |
| `Subscriptions` | Subscriptions | Abonamente | translated |
| `Take control of your money` | Take control of your money | Preia controlul banilor tăi | translated |
| `Tap to add` | Tap to add | Apasă pentru a adăuga | translated |
| `Target is a multiple of your monthly income` | Target is a multiple of your monthly income | Ținta este un multiplu al venitului lunar | translated |
| `Target is a specific amount` | Target is a specific amount | Ținta este o sumă specifică | translated |
| `Target multiplier` | Target multiplier | Multiplicator țintă | translated |
| `Target reached!` | Target reached! | Țintă atinsă! | translated |
| `Target:` | Target: | Țintă: | translated |
| `Target: %@` | Target: %@ | Țintă: %@ | translated |
| `Target: months of income` | Target: months of income | Țintă: luni de venit | translated |
| `That's %@/month` | That's %@/month | Adică %@/lună | translated |
| `These expenses will be paid from this account` | These expenses will be paid from this account | Aceste cheltuieli vor fi plătite din acest cont | translated |
| `These stay in your main account for automatic payments` | These stay in your main account for automatic payments | Acestea rămân în contul principal pentru plăți automate | translated |
| `This account receives automatic savings` | This account receives automatic savings | Acest cont primește economii automate | translated |
| `This is your starting point — we'll help you decide where every unit goes.` | This is your starting point — we'll help you decide where every unit goes. | Acesta este punctul tău de plecare — te vom ajuta să decizi unde merge fiecare unitate. | translated |
| `This month's savings` | This month's savings | Economiile lunii acesteia | translated |
| `Tip: Do these transfers right after payday for best results!` | Tip: Do these transfers right after payday for best results! | Sfat: Fă aceste transferuri imediat după ziua de salariu pentru cele mai bune rezultate! | translated |
| `Total: %@` | Total: %@ | Total: %@ | translated |
| `Transportation` | Transportation | Transport | translated |
| `Triple your savings temporarily` | Triple your savings temporarily | Triplează-ți economiile temporar | translated |
| `Watch your progress grow` | Watch your progress grow | Urmărește cum crește progresul tău | translated |
| `We've set up some common accounts. Adjust them to match your setup.` | We've set up some common accounts. Adjust them to match your setup. | Am configurat câteva conturi comune. Ajustează-le pentru a se potrivi configurației tale. | translated |
| `What should we call you?` | What should we call you? | Cum să te strigăm? | translated |
| `Where does your money live?` | Where does your money live? | Unde îți țin banii? | translated |
| `Where should this go?` | Where should this go? | Unde ar trebui să meargă? | translated |
| `Where your salary lands` | Where your salary lands | Unde îți intră salariul | translated |
| `Your Accounts` | Your Accounts | Conturile tale | translated |
| `Your First Month` | Your First Month | Prima ta lună | translated |
| `Your Goals` | Your Goals | Obiectivele tale | translated |
| `Your Transfers` | Your Transfers | Transferurile tale | translated |
| `Your flexible spending money` | Your flexible spending money | Banii tăi pentru cheltuieli flexibile | translated |
| `Your goals fill in priority order. When one completes, money flows to the next!` | Your goals fill in priority order. When one completes, money flows to the next! | Obiectivele se completează în ordinea priorității. Când unul este complet, banii curg către următorul! | translated |
| `Your name` | Your name | Numele tău | translated |
| `Your primary account is where your salary lands` | Your primary account is where your salary lands | Contul tău principal este unde îți intră salariul | translated |
| `available for your goals` | available for your goals | disponibil pentru obiectivele tale | translated |
| `e.g., Joint Account` | e.g., Joint Account | ex: Cont comun | translated |
| `going to your accounts` | going to your accounts | se duc către conturile tale | translated |
| `going to your goals` | going to your goals | se duce către obiectivele tale | translated |

### 5.4 `dashboard` — Features/Dashboard

Path: `Packages/Features/Dashboard/Sources/Dashboard/Resources/Localizable.xcstrings`  
Bundle: `.module` (Dashboard) · 41 keys · 38 explicit EN · 37 RO

| Key (EN source string) | EN | RO | RO state |
|---|---|---|---|
| `%lld%%` | _(= key)_ | **MISSING** | — |
| `+%@` | _(= key)_ | **MISSING** | — |
| `Account Balances` | Account Balances | Solduri conturi | translated |
| `All amounts add up correctly` | All amounts add up correctly | Toate sumele sunt corecte | translated |
| `Available` | Available | Disponibil | translated |
| `Available This Month` | Available This Month | Disponibil luna aceasta | translated |
| `Cancel` | Cancel | Anulează | translated |
| `Complete onboarding to start tracking your finances` | Complete onboarding to start tracking your finances | Completează introducerea pentru a începe să îți urmărești finanțele | translated |
| `Completes fund to 100%!` | Completes fund to 100%! | Completează fondul la 100%! | translated |
| `Continue` | Continue | Continuă | translated |
| `Current balance` | Current balance | Sold curent | translated |
| `Did you use any savings this month?` | Did you use any savings this month? | Ai folosit economii luna aceasta? | translated |
| `Done - I made the transfers` | Done - I made the transfers | Gata - Am făcut transferurile | translated |
| `Emergency Fund` | Emergency Fund | Fond de urgență | translated |
| `Expense Breakdown` | Expense Breakdown | Detalii cheltuieli | translated |
| `Expenses` | Expenses | Cheltuieli | translated |
| `How much did you receive?` | How much did you receive? | Cât ai primit? | translated |
| `Income` | Income | Venit | translated |
| `Last month: %@` | Last month: %@ | Luna trecută: %@ | translated |
| `Monthly Summary` | Monthly Summary | Sumar lunar | translated |
| `New Month` | New Month | Lună nouă | translated |
| `No data yet` | No data yet | Nicio dată încă | translated |
| `No expenses set` | No expenses set | Nicio cheltuială setată | translated |
| `Personal` | Personal | Personal | translated |
| `Personal Spending` | Personal Spending | Bani personali | translated |
| `Primary` | Primary | Principal | translated |
| `Process this month's salary` | Process this month's salary | Procesează salariul lunii | translated |
| `Savings` | Savings | Economii | translated |
| `Step %d of %d` | Step %d of %d | Pasul %d din %d | translated |
| `Step %lld of %lld` | Step %1$lld of %2$lld | **MISSING** | — |
| `Target: %@× monthly income` | Target: %@× monthly income | Țintă: %@× venit lunar | translated |
| `Target: %lld× monthly income` | _(= key)_ | **MISSING** | — |
| `Target: %lld× monthly income (capped at %@)` | Target: %1$lld× monthly income (capped at %2$@) | Țintă: %1$lld× venit lunar (plafonat la %2$@) | translated |
| `Transfer to %@` | Transfer to %@ | Transfer către %@ | translated |
| `Transfers to make` | Transfers to make | Transferuri de făcut | translated |
| `Update your account balances` | Update your account balances | Actualizează soldurile conturilor | translated |
| `Your Transfer Plan` | Your Transfer Plan | Planul tău de transfer | translated |
| `for %@` | for %@ | pentru %@ | translated |
| `remaining money` | remaining money | bani rămași | translated |
| `stays for automatic payments` | stays for automatic payments | rămâne pentru plăți automate | translated |
| `was %@ last month` | was %@ last month | a fost %@ luna trecută | translated |

### 5.5 `expenses` — Features/Expenses

Path: `Packages/Features/Expenses/Sources/Expenses/Resources/Localizable.xcstrings`  
Bundle: `.module` (Expenses) · 55 keys · 0 explicit EN · 53 RO

| Key (EN source string) | EN | RO | RO state |
|---|---|---|---|
| `` | _(= key)_ | **MISSING** | — |
| `(%@)` | _(= key)_ | **MISSING** | — |
| `Account` | _(= key)_ | Cont | translated |
| `Add` | _(= key)_ | Adaugă | translated |
| `Add Expense` | _(= key)_ | Adaugă cheltuială | translated |
| `Add Subcategory` | _(= key)_ | Adaugă subcategorie | translated |
| `Add your first expense to start tracking your budget.` | _(= key)_ | Adaugă prima cheltuială pentru a începe urmărirea bugetului. | translated |
| `Amount` | _(= key)_ | Sumă | translated |
| `Annual` | _(= key)_ | Anual | translated |
| `Are you sure you want to delete this expense? This action cannot be undone.` | _(= key)_ | Ești sigur că vrei să ștergi această cheltuială? Acțiunea nu poate fi anulată. | translated |
| `Cancel` | _(= key)_ | Anulează | translated |
| `Categories` | _(= key)_ | Categorii | translated |
| `Category` | _(= key)_ | Categorie | translated |
| `Category Name` | _(= key)_ | Nume categorie | translated |
| `Choose which account this expense is paid from.` | _(= key)_ | Alege din ce cont se plătește această cheltuială. | translated |
| `Collapse All` | _(= key)_ | Restrânge toate | translated |
| `Color` | _(= key)_ | Culoare | translated |
| `Custom Categories` | _(= key)_ | Categorii personalizate | translated |
| `Custom Subcategories` | _(= key)_ | Subcategorii personalizate | translated |
| `Default` | _(= key)_ | Implicit | translated |
| `Default Categories` | _(= key)_ | Categorii implicite | translated |
| `Default Subcategories` | _(= key)_ | Subcategorii implicite | translated |
| `Default categories cannot be deleted.` | _(= key)_ | Categoriile implicite nu pot fi șterse. | translated |
| `Delete` | _(= key)_ | Șterge | translated |
| `Delete Expense` | _(= key)_ | Șterge cheltuială | translated |
| `Details` | _(= key)_ | Detalii | translated |
| `Disabled expenses won't be included in your budget calculations.` | _(= key)_ | Cheltuielile dezactivate nu vor fi incluse în calculele bugetare. | translated |
| `Done` | _(= key)_ | Gata | translated |
| `Edit` | _(= key)_ | Editează | translated |
| `Edit Expense` | _(= key)_ | Editează cheltuială | translated |
| `Enabled` | _(= key)_ | Activat | translated |
| `Expand All` | _(= key)_ | Extinde toate | translated |
| `Expenses` | _(= key)_ | Cheltuieli | translated |
| `Frequency` | _(= key)_ | Frecvență | translated |
| `Icon` | _(= key)_ | Pictogramă | translated |
| `Manage Categories` | _(= key)_ | Gestionează categorii | translated |
| `Monthly` | _(= key)_ | Lunar | translated |
| `Monthly Equivalent` | _(= key)_ | Echivalent lunar | translated |
| `Name` | _(= key)_ | Nume | translated |
| `New Category` | _(= key)_ | Categorie nouă | translated |
| `New Category...` | _(= key)_ | Categorie nouă... | translated |
| `New Subcategory` | _(= key)_ | Subcategorie nouă | translated |
| `No Expenses Yet` | _(= key)_ | Nicio cheltuială încă | translated |
| `None` | _(= key)_ | Niciunul | translated |
| `Notes` | _(= key)_ | Note | translated |
| `Pay From` | _(= key)_ | Plătește din | translated |
| `Preview` | _(= key)_ | Previzualizare | translated |
| `Primary` | _(= key)_ | Principal | translated |
| `Save` | _(= key)_ | Salvează | translated |
| `Search expenses` | _(= key)_ | Caută cheltuieli | translated |
| `Subcategory` | _(= key)_ | Subcategorie | translated |
| `Total %@ Expenses` | _(= key)_ | Cheltuieli %@ totale | translated |
| `Uncategorized` | _(= key)_ | Necategorizat | translated |
| `enabled` | _(= key)_ | active | translated |
| `subcategories` | _(= key)_ | subcategorii | translated |
