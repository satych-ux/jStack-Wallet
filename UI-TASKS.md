# UI build — task decomposition

Presentation layer only. Data and domain get stubs so the UI compiles; the real
implementations come later and the stubs are deleted.

Spec: `DESIGN.md`. Screen requirements: `SPEC.md`. Build rules:
`.claude/skills/jwallet-lite-build/SKILL.md`.

## How to run this

Start every screen task by opening that screen's reference screenshot in
`docs/screenshots/` — the table at the top of `DESIGN.md` maps screens to
filenames. Look at the image before writing widget code, and again before
calling the task done.

One task per Claude Code session. A task is done only when **all** of these hold:

1. Its widget tests pass: `cd app && flutter test`
2. `cd app && flutter analyze` reports zero issues
3. The screen renders at 360 and 430 logical pixels with no overflow
4. No literal hex or inline `TextStyle` anywhere outside `core/theme`
5. You can explain every file in the task

Do not start the next task until the previous one meets all five.

After each task, run a critic pass in a fresh session:
> Review the diff for task N against DESIGN.md. List every deviation in colour,
> size, spacing, font family or weight. List missing states. Fix nothing yet.

---

## T0 — Theme and stubs

**Build**
- `core/theme/app_colors.dart`, `app_text_styles.dart`, `app_spacing.dart`, `app_theme.dart`
- `core/widgets/brand_mark.dart`
- Stub domain and data so presentation compiles. For each feature
  (`auth`, `wallet`, `transfer`, `transactions`):
  - `domain/entities/` — plain immutable classes with the fields `DESIGN.md` shows
  - `domain/repositories/` — abstract class per feature
  - `data/repositories/fake_*_repository.dart` — returns the sample values

**Every stub file starts with this line:**
```dart
// TEMPORARY presentation scaffolding. Delete when the data slice lands.
```

**Tests** — `test/theme_test.dart`
- `AppColors.brand` is `0xFFB71A1A`, `ink` is `0xFF0F0F0F`, `success` is `0xFF1A6B4A`
- `AppTextStyles.balance.fontFamily` resolves to Space Mono, weight 700, size 34
- `AppTextStyles.display` resolves to Sora, weight 600
- `AppTextStyles.body` resolves to Manrope, weight 500
- `appTheme.cardTheme.elevation == 0` and `appTheme.appBarTheme.elevation == 0`

---

## T1 — Shared widgets

**Build** `core/widgets/`: `JWalletButton`, `JWalletTextField`, `AmountField`,
`StatusLabel`, `FilterPill`, `DetailCard`, `DetailRow`, `EmptyStateView`,
`ErrorStateView`, `AppTopBar`, `QuickActionCard`, `BalancePanel`,
`TransactionRail`, `TransactionRow`.

Plus `core/widgets/shimmer/`: `ShimmerBox`, `ShimmerGroup` (owns the single
`AnimationController` and provides it to descendants), `BalancePanelShimmer`,
`TransactionRowShimmer`, `DetailCardShimmer`.

**Tests** — `test/core/widgets/`
- `JWalletButton`: primary renders its label; `onPressed` fires once on tap;
  disabled variant does not fire; loading variant shows a
  `CircularProgressIndicator` and does not fire; secondary has a border
- `JWalletTextField`: renders label and hint; error variant shows the message
  and the border is `brand`; the eye toggle flips `obscureText`
- `AmountField`: shows the `₹` prefix; text style is Space Mono 700
- `StatusLabel`: `SUCCESS` is `success`, `PENDING` is `inkFaint`, `FAILED` is `brand`
- `FilterPill`: selected has `ink` background and `white` label; unselected inverts
- `TransactionRow`: debit shows a `−` prefix and a `brand` dot; credit shows `+`
  and a `success` dot; reference and date both render
- `BalancePanel`: renders amount, wallet id and masked account; background is `ink`
- `QuickActionCard`: disabled variant shows the `SOON` pill and does not fire
- `EmptyStateView` / `ErrorStateView`: render their copy; Retry fires its callback
- `ShimmerBox`: honours width, height and radius; `onDark: true` uses the dark
  base colour, default uses the light one
- `ShimmerGroup`: N descendant boxes drive exactly one `AnimationController`
  (assert by counting tickers, not by eye)
- `BalancePanelShimmer`: background is `ink`; its height equals a populated
  `BalancePanel` built with sample data (assert no layout jump)
- `TransactionRowShimmer`: its height equals a populated `TransactionRow`
- `DetailCardShimmer`: renders six rows and the real card border
- Every shimmer section is wrapped in a `RepaintBoundary`
- Golden-free rule: assert colours and styles by reading the widget, not by image

**Abstraction check before T1 is done.** No generics anywhere in
`core/widgets/`. No abstract widget base classes. No widget takes more than six
parameters. Variants are enums, not subclasses. If a widget is used by only one
screen, it belongs in that screen's folder, not `core/widgets/`.

---

## T2 — Router

**Build** `core/router/app_routes.dart` (path + name constants, no literals
elsewhere) and `app_router.dart` (go_router, all seven routes, a `redirect`
guard reading a stub auth flag, `errorBuilder`).

Routes: `/login`, `/dashboard`, `/transfer`, `/transfer/confirm`,
`/transfer/result`, `/transactions`, `/transactions/:id`.

**Tests** — `test/core/router/router_test.dart`
- Unauthenticated start resolves to `/login`
- Authenticated start resolves to `/dashboard`
- Authenticated navigation to `/login` redirects to `/dashboard`
- `/transactions/TXN10001` parses `id` as `TXN10001`
- An unknown path renders the error page
- Every constant in `AppRoutes` is reachable in the router

---

## T3 — Login

**Build** `features/auth/presentation/screens/login_screen.dart` plus any
screen-local widgets.

**Tests**
- Renders brand mark, wordmark, headline, both fields and the Sign in button
- Password field is obscured by default; the toggle reveals it
- Empty email shows "Enter your email"; malformed email shows the format error
- Empty password shows its error
- Valid input calls the submit callback exactly once with both values
- `isLoading: true` shows the loading button and blocks a second tap
- `errorMessage` renders in `brand` and the screen does not navigate
- Demo-credentials card shows `demo@jstack.co` and `Demo@123`

---

## T4 — Dashboard

**Build** `features/wallet/presentation/screens/dashboard_screen.dart`.

**Tests**
- Renders greeting, user name, avatar initials
- Balance, wallet id and masked account come from the passed-in model,
  never a literal in the widget tree
- Exactly five transaction rows render
- `Add money` is disabled and shows `SOON`
- `Send money` and `History` fire their callbacks
- `See all` fires its callback
- Each section loads independently: balance loaded + transactions loading
  renders a real `BalancePanel` beside `TransactionRowShimmer` rows
- The reverse also holds: `BalancePanelShimmer` beside real transaction rows
- Loading shows five `TransactionRowShimmer`, not a spinner over the whole page
- Quick actions never shimmer; they render immediately in every state
- Pull-to-refresh keeps existing content visible and does not swap in shimmer
- Error state renders `ErrorStateView` and Retry fires
- Empty state renders when the list is empty
- `RefreshIndicator` is present and its `onRefresh` fires

---

## T5 — Send money

**Build** `features/transfer/presentation/screens/send_money_screen.dart`.

**Tests**
- All four fields render in the order Amount, Beneficiary, Mobile, Remarks
- Available balance strip shows the passed-in value
- Empty beneficiary blocks submit and shows its error
- Mobile shorter than 10 digits, longer than 10, or non-numeric each show
  "Enter a valid 10-digit mobile number"
- Amount of `0`, a negative, or non-numeric shows "Enter an amount greater than zero"
- Amount with three decimals is rejected
- Remarks empty is valid
- Valid input fires the callback once with the trimmed values
- The screen does **not** block submit when the amount exceeds the balance
  (the backend owns that verdict)

---

## T6 — Confirmation

**Build** `features/transfer/presentation/screens/confirm_transfer_screen.dart`.

**Tests**
- Amount, beneficiary, mobile, remarks and balance-after all render from the
  passed-in model
- Fee row shows `₹0.00`
- The request key renders
- `Confirm transfer` fires once; a second tap while `isSubmitting` does not fire
- `isSubmitting: true` shows the loading button
- `Edit details` fires the back callback

---

## T7 — Result

**Build** `features/transfer/presentation/screens/transfer_result_screen.dart`,
one widget, a `success` / `failure` parameter.

**Tests**
- Success: check icon, `successTint` halo, reference, date-time,
  `SUCCESS` in `success`, updated balance
- Success: `Back to dashboard` and `View transaction` both fire
- Failure: alert icon, `brandTint` banner, the reason text, the status code
- Failure: unchanged balance renders
- Failure: `Try again` and `Back to dashboard` both fire
- The same widget renders both without a second screen class

---

## T8 — History

**Build** `features/transactions/presentation/screens/transactions_screen.dart`.

**Tests**
- Rows render newest first
- Rows are grouped under date headers
- Typing a reference filters to matching rows
- Typing a name filters to matching rows
- Search is case-insensitive
- `Credit` pill shows only credits; `Debit` only debits; `All` restores
- Filters and search combine
- A filter that matches nothing shows the "no results" copy, not the
  "no transactions yet" copy
- Empty source list shows the empty state
- Loading shows six `TransactionRowShimmer`; error shows `ErrorStateView`
- Search field and filter pills render and stay usable while the list shimmers
- Tapping a row fires with that row's id

---

## T9 — Details

**Build** `features/transactions/presentation/screens/transaction_details_screen.dart`.

**Tests**
- Type pill shows `DEBIT` with a `brand` dot; `CREDIT` with a `success` dot
- Amount carries `−` for debit and `+` for credit
- All six rows render: id, beneficiary, mobile, type, date-time, remarks
- A transaction with no remarks hides that row rather than showing it empty
- Status renders with the right colour
- Loading renders `DetailCardShimmer` plus a shimmered hero amount
- Back fires

---

## T10 — Verify

Not a build task. In a fresh session:

- `cd app && flutter analyze` — zero issues
- `cd app && flutter test` — all green
- Run the app; walk all seven screens; confirm every one matches `DESIGN.md`
- Grep for stray literals: `grep -rn "Color(0x" app/lib --include=*.dart | grep -v core/theme`
- Grep for shadows: `grep -rn "BoxShadow\|elevation:" app/lib --include=*.dart`
- Confirm every stub still carries its TEMPORARY header and is listed for deletion
- Screenshot all seven screens into `docs/screenshots/`
