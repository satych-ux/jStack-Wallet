# jWallet Lite — UI specification

Authoritative values for the presentation layer. Derived from the jStack brand
(jstack.co).

## Before building any screen

**Open that screen's reference screenshot in `docs/screenshots/` and look at
it.** Read the PNG with your image-reading tool before writing any widget code,
and look at it again before calling the task done. Do not build from this text
alone.

| Screen | Screenshot |
|---|---|
| Login | `docs/screenshots/1 · Login@1x.png` |
| Wallet dashboard | `docs/screenshots/2 · Wallet dashboard@1x.png` |
| Send money | `docs/screenshots/3 · Send money@1x.png` |
| Transfer confirmation | `docs/screenshots/4 · Transfer confirmation@1x.png` |
| Transfer success | `docs/screenshots/5a · Transfer success@1x.png` |
| Transfer failure | `docs/screenshots/5b · Transfer failure@1x.png` |
| Transaction history | `docs/screenshots/6 · Transaction history@1x.png` |
| Transaction details | `docs/screenshots/7 · Transaction details@1x.png` |
| Tokens, components and states | `docs/screenshots/8 · Design system@1x.png` |

Filenames contain spaces and a middle dot, so quote the whole path when you
open one. The design-system sheet is the reference for **T1 shared widgets**:
it shows every button, input, status and empty/error/loading state in one
image. Open it before building any shared widget.

If a screenshot is missing, say so and build from this file. Where this file
and a screenshot disagree, **this file wins** — the numbers here are measured,
the image is only a render.

---

## 1. Tokens

### Colour — `core/theme/app_colors.dart`

| Token | Hex | Use |
|---|---|---|
| `ink` | `#0F0F0F` | Primary text, dark balance panel, selected pill |
| `inkMuted` | `#6A6A6A` | Secondary text, body copy |
| `inkFaint` | `#767676` | Mono labels, helper text, placeholders |
| `line` | `#E3E3E3` | Hairlines, borders, dividers |
| `surface` | `#F7F7F7` | Recessed rows and strips |
| `white` | `#FFFFFF` | Page background, cards |
| `brand` | `#B71A1A` | Primary button, errors, debit rail dot |
| `brandPressed` | `#8E1414` | Primary button pressed |
| `brandTint` | `#F8EDED` | Failure banner background |
| `success` | `#1A6B4A` | Success status, credit rail dot |
| `successTint` | `#ECF4F0` | Success icon halo |
| `onDarkMuted` | `#9E9E9E` | Labels on the dark panel |
| `onDarkValue` | `#E8E8E8` | Values on the dark panel |
| `darkDivider` | `#2B2B2B` | Divider inside the dark panel |
| `skeleton` | `#EDEDED` / `#F2F2F2` | Loading placeholder bars |

No shadows anywhere in this app. Separation is hairlines and `surface`.

### Type — `core/theme/app_text_styles.dart`

Three families. Add to `pubspec.yaml` via `google_fonts`, or bundle.

| Style | Family | Weight | Size | Height | Letter spacing |
|---|---|---|---|---|---|
| `balance` | Space Mono | 700 | 34 | 1.0 | -0.01em |
| `amountHero` | Space Mono | 700 | 40 | 1.0 | -0.02em |
| `amountDetail` | Space Mono | 700 | 38 | 1.0 | -0.02em |
| `display` | Sora | 600 | 27 | 1.18 | -0.02em |
| `headline` | Sora | 600 | 24 | 1.2 | -0.015em |
| `titleAppBar` | Sora | 600 | 18 | 1.2 | -0.01em |
| `titleName` | Sora | 600 | 20 | 1.2 | -0.01em |
| `wordmark` | Sora | 700 | 20 | 1.2 | -0.01em |
| `body` | Manrope | 500 | 15 | 1.5 | 0 |
| `bodySmall` | Manrope | 500 | 14 | 1.5 | 0 |
| `caption` | Manrope | 400 | 12 | 1.5 | 0 |
| `rowTitle` | Manrope | 600 | 14 | 1.2 | 0 |
| `buttonLabel` | Manrope | 600 | 15 | 1.0 | 0 |
| `pillLabel` | Manrope | 600 | 13 | 1.0 | 0 |
| `monoLabel` | Space Mono | 400 | 11 | 1.2 | 0.14em, uppercase |
| `monoLabelTight` | Space Mono | 400 | 11 | 1.2 | 0.12em, uppercase |
| `monoMeta` | Space Mono | 400 | 11 | 1.2 | 0 |
| `monoValue` | Space Mono | 400 | 14 | 1.2 | 0 |
| `monoValueBold` | Space Mono | 700 | 14 | 1.2 | 0 |
| `monoStatus` | Space Mono | 700 | 10 | 1.2 | 0.1em, uppercase |
| `monoStatusLarge` | Space Mono | 700 | 12 | 1.2 | 0.1em, uppercase |

**Rule:** every money figure, transaction reference, wallet id, account number,
date-time and status label is Space Mono. Every sentence of prose is Manrope.
Every heading is Sora. No exceptions.

### Spacing and shape — `core/theme/app_spacing.dart`

- Scale: 4, 8, 10, 12, 14, 16, 18, 20, 22, 26, 30, 34, 44.
- Screen horizontal padding: **20** (login uses **24**).
- Screen top padding: **48** for app-bar screens, **52** dashboard, **56** login, **72** result screens.
- Screen bottom padding: **24**.
- Radius: card `14`, dark panel `16`, button `12`, input `12`, quick action `14`, pill `999`, avatar `999`.
- Border width: `1`. Focused input border: `1`, colour `ink`.
- Minimum touch target: `44`.

---

## 2. Shared components

All under `core/widgets/` unless a feature owns it outright.

### `JWalletButton`
Variants: `primary`, `secondary`, `disabled`, `loading`.
- Height `52`, full width, radius `12`, label `buttonLabel`.
- primary: bg `brand`, text `white`. Pressed: bg `brandPressed`.
- secondary: bg `white`, border `1` `line`, text `ink`.
- disabled: bg `line`, text `inkFaint`, no tap.
- loading: bg `brand`, an 18px white spinner + label, no tap.

### `JWalletTextField`
- Height `52`, radius `12`, horizontal padding `16`, text `body`.
- Default border `line`; focused border `ink`; error border `brand`.
- Label above, `monoLabel`, gap `8`.
- Error message below, gap `7`: a `5px` `brand` dot, gap `7`, then `caption` in `brand`.
- Optional trailing widget sized `44x44` (password eye toggle).
- Optional leading prefix box (mobile `+91`): padding `0 14`, bg `surface`,
  right border `1` `line`, text `monoValue` in `inkMuted`.

### `AmountField`
Same as above but height `62`, a `₹` prefix in Space Mono 700 22 `inkFaint`,
gap `8`, and input text Space Mono 700 22 `ink`.

### `BalancePanel`
- Radius `16`, bg `ink`, padding `22 22 18`.
- Row: a `2x12` `brand` bar, gap `10`, `AVAILABLE BALANCE` in `monoLabel` `onDarkMuted`.
- Gap `12`, balance in `balance` style, `white`.
- Gap `18`, `1px` `darkDivider`.
- Gap `14`, two columns: left `WALLET ID` / value, right `ACCOUNT` / value,
  right-aligned. Labels Space Mono 10 `0.12em` `#8A8A8A`; values `monoValue` 12 `onDarkValue`.

### `QuickActionCard`
- Height `84`, radius `14`, border `1` `line`, bg `white`.
- Centre column: 22px stroke icon (stroke width 1.7), gap `9`, label Manrope 600 12.
- Disabled variant: icon and label `inkFaint`, plus a `SOON` pill top-right
  (Space Mono 9, `0.1em`, border `1` `line`, radius `999`, padding `2 6`).

### `TransactionRail` + `TransactionRow`
The signature element. A list section renders:
- A `1px` `line` vertical rail at `left: 13`, inset `14` top and bottom.
- Each row: height driven by content, padding `11 0 11 36` (dashboard) or `10 0 10 36` (history).
- Dot: `9x9`, radius `999`, centred vertically, `left: 9`, with a `3px` `white`
  ring (Flutter: a `13x13` white circle behind a `9x9` coloured circle).
  Debit → `brand`. Credit → `success`.
- Left column: name in `rowTitle` `ink`; gap `3`; a row of `monoMeta` `inkFaint`
  spans with gap `10` (reference, then date or type).
- Right column, right-aligned: amount in `monoValueBold` `ink`, prefixed `−` or `+`;
  gap `3`; status in `monoStatus`.

### `StatusLabel`
`monoStatus`. `SUCCESS` → `success`. `PENDING` → `inkFaint`. `FAILED` → `brand`.

### `DetailCard` + `DetailRow`
- Card: radius `14`, border `1` `line`, clipped.
- Row: padding `15 16`, label left in `monoLabelTight` `inkFaint`, value right.
- Value is `monoValue`/`monoValueBold` for ids, amounts, dates, phone numbers;
  Manrope 600 14 for human names; Manrope 14 for free text.
- Divider between rows: `1px` `line`, full bleed.
- A final emphasised row may take bg `surface`.

### `FilterPill`
Height `36`, padding `0 16`, radius `999`, label `pillLabel`.
Selected: bg `ink`, border `ink`, text `white`. Unselected: bg `white`, border `line`, text `ink`.

### `EmptyStateView`
Radius `12`, border `1` `line`, padding `20`, centred.
Title Sora 600 15 `ink`; gap `6`; body `caption` `inkMuted`.

### `ErrorStateView`
Radius `12`, border `1` `line`, padding `16`, row with text left and a
`Retry` pill right (height `36`, padding `0 14`, radius `999`, border `line`).
Title Manrope 600 13 `ink`; gap `3`; body `caption` `inkMuted`.

### Shimmer and loading

**Principle.** Shimmer means "data is being fetched and will appear here".
A button spinner means "an action is running". Never both for the same wait.
So Dashboard, History and Details shimmer; Login, Confirmation and Result use
the loading button variant instead.

**Sections load independently.** Each section owns its own bloc and its own
loading state, so the balance can resolve while transactions are still loading.
Fire the requests in parallel — do not chain them — and let each section swap
its shimmer for content as it arrives. The stagger comes from differing
response times, not from an artificial delay or a waterfall.

#### `ShimmerBox`
The primitive. Parameters: `width`, `height`, `radius` (default `4`),
`onDark` (default `false`).

| | Base | Highlight |
|---|---|---|
| On white or `surface` | `#EBEBEB` | `#F5F5F5` |
| On the dark balance panel (`onDark: true`) | `#2B2B2B` | `#3C3C3C` |

Animation: a horizontal `LinearGradient` sweep, period **1400ms**, left to
right, looping. One `AnimationController` per shimmering section, not one per
box — share it down the tree so twenty boxes do not drive twenty controllers.

Wrap each shimmering section in a `RepaintBoundary`. The sweep repaints
continuously; without the boundary it dirties the whole screen every frame,
which is exactly the rebuild problem this design is meant to avoid.

**Geometry must match the real content.** Every shimmer block takes the height
and radius of the widget it stands in for, so nothing jumps when content
arrives. Verify by screenshotting loading and loaded states at the same size.

#### `BalancePanelShimmer`
Keeps the real panel: radius `16`, bg `ink`, padding `22 22 18`. Inside, with
`onDark: true`:
- `120x11` box (stands in for the label row, including the red bar)
- gap `12`, `190x28` radius `6` (the balance figure)
- gap `18`, the real `1px` `darkDivider`
- gap `14`, two columns: each a `70x9` box, gap `4`, a `96x12` box;
  right column right-aligned

#### `TransactionRowShimmer`
Same padding as a real row (`11 0 11 36` dashboard, `10 0 10 36` history), and
the real rail hairline stays visible.
- Dot position: a `9x9` circle in base colour, no highlight sweep
- Left: `60%` width `x11`, gap `7`, `38%` width `x9`
- Right: `70x11`, gap `6`, `44x8`

Render **5** on the dashboard and **6** on history, under a single shared
controller.

#### `DetailCardShimmer`
The real card chrome (radius `14`, border `1` `line`) with six rows of
padding `15 16`, each a `90x10` box left and a `120x12` box right, separated
by the real `1px` `line` dividers.

#### Where shimmer appears

| Screen | Shimmers | Never shimmers |
|---|---|---|
| Dashboard | header name, balance panel, recent activity list | quick actions, pull-to-refresh hint |
| History | the grouped list and its date headers | search field, filter pills, app bar |
| Details | hero amount, status, detail card | app bar, back button |
| Send money | the available-balance strip only | the form fields |
| Login, Confirmation, Result | nothing | — |

On **pull-to-refresh**, keep the existing content on screen and let
`RefreshIndicator` show progress. Do not replace loaded content with shimmer —
that reads as data loss. Shimmer is for a first load or a retry after an error.

### `TransactionSkeleton`
Row, padding `12 0`: a `9x9` `line` circle, gap `12`, a column with a
60%-width `11px` `skeleton` bar, gap `7`, a 38%-width `9px` `#F2F2F2` bar;
then a `70x11` `skeleton` bar on the right. All radius `4`.

### `AppTopBar`
Height `44`, row with a `44x44` back button (22px chevron, stroke 1.8, `ink`),
gap `4`, title in `titleAppBar`. Offset the row `-10` left so the icon's
touch target aligns to the 20px screen padding.

### `BrandMark`
40x40. Two rounded rects plus a dot:
`rect(1,8,27,19,r5)` fill `brand`; `rect(11,13,27,19,r5)` fill `ink`;
`circle(31,22.5,r2.6)` fill `white`. Draw with `CustomPainter` or inline SVG.

---

## 3. Screens

Canvas frame is `390x844`. Build fluid — no hardcoded screen width.

### 3.1 Login — `/login`
Padding `56 24 28`. Column:
BrandMark · gap 16 · `jWallet Lite` (`wordmark`) · gap 36 · `Sign in to move money.`
(`display`, max width 260) · gap 10 · body copy (`bodySmall` `inkMuted`, max width 280)
· gap 34 · EMAIL field · gap 18 · PASSWORD field (obscured, eye toggle)
· gap 6 · primary button `Sign in` · gap 22 · demo-credentials card · spacer
· centred `caption` `inkFaint`: "Mock environment. No real funds move."

Demo card: radius `14`, border `1` `line`, bg `surface`, padding `16`.
`DEMO CREDENTIALS` in `monoLabel`; gap 12; two space-between rows,
label `bodySmall`-13 `inkMuted`, value `monoValue`-13 `ink`, gap 8 between rows.

### 3.2 Dashboard — `/dashboard`
Padding `52 20 24`. Column:
Header row (left: `WELCOME BACK` `monoLabel`, gap 5, name `titleName`;
right: `44x44` avatar circle bg `ink`, initials Manrope 600 14 `white`)
· gap 22 · `BalancePanel` · gap 18 · three `QuickActionCard` in a 3-column grid, gap 10
· gap 26 · section row (`RECENT ACTIVITY` `monoLabel` | `See all` Manrope 600 13 `brand`)
· gap 14 · rail with **5** rows · spacer
· centred hint: 13px refresh icon, gap 8, `caption` `inkFaint` "Pull to refresh".

Wrap the scroll view in `RefreshIndicator` (colour `brand`).

### 3.3 Send money — `/transfer`
Padding `48 20 24`. Column:
`AppTopBar("Send money")` · gap 14 · balance strip (radius 12, bg `surface`,
padding `14 16`, `AVAILABLE` `monoLabel` left, amount `monoValueBold`-15 right)
· gap 26 · fields with gap 20 in order: **Amount** (`AmountField`), Beneficiary name,
Mobile number (with `+91` prefix), Remarks (with a right-aligned `Optional` hint,
Manrope 11 `inkFaint`) · spacer · `caption` `inkFaint` explaining the backend owns
the balance · gap 14 · primary button `Review transfer`.

### 3.4 Confirmation — `/transfer/confirm`
Padding `48 20 24`. Column:
`AppTopBar("Review transfer")` · gap 30 · centred block
(`YOU ARE SENDING` `monoLabel`, gap 12, amount `amountHero`, gap 10,
`to <name>` `bodySmall` `inkMuted`) · gap 30 · `DetailCard` with rows
BENEFICIARY, MOBILE, REMARKS, TRANSFER FEE, and BALANCE AFTER (bg `surface`,
value `monoValueBold`) · gap 18 · `caption` `inkFaint` on single-send and the
request key · spacer · centred request-key line (`REQUEST KEY` Space Mono 10
`0.12em` `inkFaint`, gap 8, the key, Space Mono 10 `inkFaint`) · gap 16 ·
primary `Confirm transfer` · gap 10 · secondary `Edit details`.

### 3.5 Result — `/transfer/result`
One screen, two states driven by a parameter.

**Success.** Padding `72 20 24`. Centred: `76x76` circle bg `successTint`
with a 32px check (stroke 2.2, `success`) · gap 22 · `Transfer successful`
(`headline`) · gap 10 · "`₹1,500.00` sent to Rahul Sharma." with the amount
in `monoValueBold` `ink` inline and the rest `bodySmall` `inkMuted`
· gap 34 · `DetailCard`: REFERENCE, DATE AND TIME, STATUS (`monoStatusLarge`
`success`), UPDATED BALANCE (bg `surface`) · gap 18 · `caption` note
· spacer · primary `Back to dashboard` · gap 10 · secondary `View transaction`.

**Failure.** Same skeleton. Circle bg `brandTint`, icon is an exclamation
(two strokes: `M12 7v7` and a dot at `12,17.4`), `brand`.
Title `Transfer not completed`; subtitle "Your wallet was not debited. Nothing has changed."
First card block is a banner: padding `16`, bg `brandTint`, reason in
`monoStatusLarge` `brand`, gap 8, explanation Manrope 13 `ink`.
Then rows BENEFICIARY, RESPONSE (status code), BALANCE (bg `surface`).
Buttons: primary `Try again`, secondary `Back to dashboard`.

### 3.6 History — `/transactions`
Padding `48 20 24`. Column:
`AppTopBar("Transactions")` · gap 12 · search field (height 48, radius 12,
border `line`, 18px magnifier `inkFaint`, gap 10, placeholder
"Search reference or name" Manrope 14) · gap 14 · three `FilterPill`
(All / Credit / Debit) gap 8 · then repeating groups:
date header `monoLabel` e.g. `20 OCTOBER 2026` · gap 8 · a rail with that day's rows.
Gap 18 between groups. Rows are tappable and push details.

### 3.7 Details — `/transactions/:id`
Padding `48 20 24`. Column:
`AppTopBar("Transaction")` · gap 26 · centred block: a type pill
(border `1` `line`, radius 999, padding `6 14`, an `8x8` dot — `brand` for
debit, `success` for credit — gap 8, `DEBIT`/`CREDIT` in `monoLabelTight` `ink`)
· gap 18 · signed amount `amountDetail` · gap 10 · status `monoStatusLarge`
· gap 30 · `DetailCard` with TRANSACTION ID, BENEFICIARY, MOBILE, TYPE,
DATE AND TIME, REMARKS · spacer · secondary `Back to transactions`.

---

## 4. Rules for the Flutter build

1. Every colour, size and text style comes from `core/theme`. No literal hex
   or `TextStyle` inside a screen or widget file.
2. No `Shadow`, `BoxShadow`, `elevation` above 0, or `Card` default elevation.
3. Lists use `ListView.builder`. Never a `Column` of mapped children.
4. `const` constructors wherever the analyzer allows.
5. No logic in `build()` — no filtering, sorting, formatting loops. Pass in
   display-ready values.
6. Screens take their display data as constructor parameters with sensible
   defaults, so each screen renders standalone before any bloc is wired.
7. Layout is fluid. Test at 360 and 430 logical pixels wide; nothing overflows.
8. Icon-only buttons carry a `tooltip` or `Semantics` label.
