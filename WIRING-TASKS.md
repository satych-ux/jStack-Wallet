# Wiring build — task decomposition

Connects the presentation layer to the running backend: network core, DI,
then data and domain per feature, then blocs.

Contract: `SPEC.md` sections 4, 5 and 9. UI spec: `DESIGN.md`.
Build rules: `.claude/skills/jwallet-lite-build/SKILL.md`.

---

## The compatibility rule

`SPEC.md` is prose. The backend is real and running. **Bind to the backend, not
to the prose.**

Before any model is written, W0 captures the backend's actual responses into
`app/test/fixtures/*.json` and every model test parses those files. A field
renamed in the backend then fails a Dart test instead of surfacing as a null at
runtime during your demo video.

Three consequences to hold onto:

1. **Fixtures are generated, never hand-written.** If you find yourself typing
   JSON into a fixture, stop and re-run the capture script.
2. **Re-capture after any backend change.** The script is one command.
3. **A model test that passes against a hand-written fixture proves nothing.**

### Money

The backend sends amounts as JSON numbers. JSON cannot carry `1500.00`, so
`1500` arrives. Parse to `double`, format for display with `NumberFormat` and
exactly 2 decimals.

This is safe here only because **the app never does arithmetic on money** —
the backend owns every balance calculation. Do not add a Dart-side sum,
difference or running total anywhere. If a screen appears to need one, it
needs a backend field instead.

---

## How to run this

One task per Claude Code session. Done means all of:

1. `cd app && flutter test` passes
2. `cd app && flutter analyze` is clean
3. The feature works against the **running backend**, checked by hand in the app
4. The matching `fake_*_repository.dart` is deleted and nothing imports it
5. You can explain every file

Critic pass after each, fresh session:
> Review the diff for task WN against SPEC.md sections 4, 5 and 9, and against
> the captured fixtures in app/test/fixtures/. List every field name, type or
> status code the Dart side assumes that the backend does not actually send.
> Fix nothing.

---

## W0 — Network core, DI and fixtures

**Capture first.** Write `scripts/capture-fixtures.sh`: with the backend
running, curl each endpoint and write the raw response bodies to
`app/test/fixtures/`:

```
login_success.json          login_401.json
profile.json                balance.json
transactions.json           transaction_details.json
transfer_success.json       transfer_409_insufficient.json
transfer_400_validation.json  transfer_409_idempotency_reuse.json
transaction_404.json
```

**Build**
- `core/config/app_config.dart` — base URL from `--dart-define`, timeouts
- `core/network/dio_client.dart` — one configured `Dio`, connect and receive
  timeouts 10s
- `core/network/auth_interceptor.dart` — attaches the bearer token; on 401
  clears the session and signals logout
- `core/error/failure.dart` — sealed: `NetworkFailure`, `TimeoutFailure`,
  `UnauthorizedFailure`, `ValidationFailure(fields)`,
  `InsufficientBalanceFailure`, `NotFoundFailure`, `ServerFailure`
- `core/error/failure_mapper.dart` — `DioException` and status code to `Failure`
- `core/di/injector.dart` — GetIt registrations, called from `main()`

**Tests**
- Every fixture file exists and is valid JSON
- 400 maps to `ValidationFailure` and carries the field names the backend sent
- 401 maps to `UnauthorizedFailure`
- 404 maps to `NotFoundFailure`
- 409 with code `INSUFFICIENT_BALANCE` maps to `InsufficientBalanceFailure`
- 409 with code `IDEMPOTENCY_KEY_REUSED` maps to its own failure, not to
  insufficient balance
- 500 maps to `ServerFailure`
- `DioExceptionType.connectionTimeout` and `receiveTimeout` map to
  `TimeoutFailure`
- `DioExceptionType.connectionError` maps to `NetworkFailure`
- The interceptor adds `Authorization: Bearer <token>` when a token is stored
  and omits the header when none is
- Every error fixture parses into the shared error shape

---

## W1 — Auth, session and the route guard

**Carried from the W0 critic pass:**
- Nothing may resolve `Dio` (or a repository that needs it) eagerly at startup
  or in `main`: without `--dart-define=API_BASE_URL` that throws before
  `runApp`. Keep registrations lazy.
- Register the session data source **once**, under both its own type and
  `TokenStore` (the interceptor reads and clears it), not as two instances.
- `AuthBloc` must subscribe to `SessionExpiredSignal.stream` before the first
  authenticated call; it is a broadcast stream and drops events nobody hears.
- Handling a sign-out twice must be harmless (logout is idempotent).
- Widget tests that pump `JWalletApp` will need DI set up once real
  repositories are read from GetIt.

**Build**
- `auth/data/models/` — `UserModel`, `LoginResponseModel` via `json_serializable`
- `auth/data/datasources/auth_remote_data_source.dart`
- `auth/data/repositories/auth_repository_impl.dart`
- `auth/data/datasources/session_local_data_source.dart` — flutter_secure_storage
- `auth/presentation/bloc/auth_bloc.dart` — sealed state, `Equatable`
- Wire `LoginScreen` to the bloc; wire the go_router `redirect` to real auth state
- **Delete** `fake_auth_repository.dart` and `core/router/temporary_fake_wiring.dart`

**Tests**
- `LoginResponseModel.fromJson` parses `login_success.json` and yields
  `accessToken`, and user id, name and email
- Parsing `login_401.json` as an error yields `UnauthorizedFailure`
- Repository stores the token in secure storage on success
- Repository returns `UnauthorizedFailure` on 401 and stores nothing
- Bloc: initial to submitting to authenticated
- Bloc: initial to submitting to failure, with no token stored
- Bloc: logout clears storage and emits unauthenticated
- Startup with a stored token calls `/users/profile`; a 401 clears it and
  lands on login
- Startup with a valid token lands on dashboard
- A 401 from any later call drives the bloc to unauthenticated

---

## W2 — Wallet and the dashboard's three sections

**Carried from the W0 critic pass:** parse money as
`(json['availableBalance'] as num).toDouble()`, never `as double`: JSON sends
whole rupees as an int. `balance_whole_rupees.json` (`"availableBalance":23950`)
is the captured fixture for the "parses from a bare integer" test.

**Build** `wallet/data/models/` (`WalletModel`, `ProfileModel`),
remote data source, repository impl, `WalletBloc` producing three
independent `Section`s: profile, balance, recent activity.
Delete `fake_wallet_repository.dart`.

**Tests**
- `WalletModel.fromJson` parses `balance.json`: `walletId`, `currency`,
  `availableBalance`, `maskedAccountNumber`
- `availableBalance` parses as `double` from a bare integer (`25450` not
  `25450.00`) and formats to `₹25,450.00`
- `ProfileModel.fromJson` parses `profile.json`
- Bloc fires the profile, balance and transaction requests **in parallel**,
  not chained — assert all three data sources are called before any completes
- Balance resolving first leaves `recent` in `SectionLoading`
- Transactions resolving first leaves `balance` in `SectionLoading`
- A failure in one section leaves the other two unaffected
- Refresh keeps sections `SectionLoaded` while refetching
- 401 propagates to logout, it does not render as a section error

---

## W3 — Transactions list and details

**Build** `TransactionModel`, remote data source, repository impl,
`TransactionsBloc` with `restartable()` or a debounce transformer on search.
Delete `fake_transactions_repository.dart`.

**Tests**
- `TransactionModel.fromJson` parses every entry in `transactions.json`
- `type`, `status` and `createdAt` map to the right Dart enums and `DateTime`
- An unknown `status` value does not throw; it falls back to a safe default
- The list arrives sorted newest first and the bloc does not re-sort it
- Search and filter are applied in the bloc, not in `build()`
- Rapid typing produces one emission per settled query, not one per keystroke
- Details parses `transaction_details.json`
- `transaction_404.json` yields `NotFoundFailure`
- Details are fetched by id, not taken from the list item

---

## W4 — Transfer, idempotency, and the two mandatory tests

**Carried from the W0 critic pass:** a missing or doubled `Idempotency-Key`
comes back as `ValidationFailure` with **empty** `fields`
(`transfer_400_missing_key.json`). It is an app bug, not user input, so the
transfer UI needs a generic message for that case, not field errors.

**Build** `TransferRequestModel`, `TransferResultModel`, remote data source
sending the `Idempotency-Key` header, repository impl, `TransferBloc` with
`droppable()` on `TransferSubmitted`. Delete `fake_transfer_repository.dart`.

**Idempotency key lifecycle:** generated when the confirmation screen opens,
held in bloc state, sent on every attempt including retries, cleared only when
a new transfer is started from the form.

**Tests**
- `TransferResultModel.fromJson` parses `transfer_success.json`:
  `transactionId`, `status`, `amount`, `currency`, `availableBalance`
- `transfer_409_insufficient.json` yields `InsufficientBalanceFailure`
- `transfer_400_validation.json` yields `ValidationFailure` with field names
- The data source sends `Idempotency-Key` on every transfer request
- A retry after `TimeoutFailure` sends the **same** key
- Starting a new transfer from the form generates a **different** key
- `droppable()`: two rapid submits produce one repository call
- **TST-03** — idle to submitting to failure(`InsufficientBalanceFailure`)
  when the repository returns 409, and the balance held in state is unchanged
- **TST-04** — idle to submitting to success, and the wallet sections are
  invalidated so the balance is refetched rather than computed locally
- Assert no Dart-side arithmetic produced the new balance: the value in state
  equals the `availableBalance` the fixture returned

---

## W5 — Integration and deliverables

Not a build task.

**Cleanup**
- `grep -rn "TEMPORARY" app/lib` returns nothing
- `grep -rn "fake_" app/lib` returns nothing
- `flutter analyze` clean, `flutter test` green, `npm test` green

**End-to-end against the running backend**
- Log in, kill the app, reopen: session persists and lands on dashboard
- Log out: returns to login and a relaunch stays there
- Transfer succeeds; dashboard balance updates; the row appears in history
- Transfer above the balance shows the insufficient-balance failure and the
  balance is unchanged
- Stop the backend mid-session: every screen shows its error state with retry
- Restart the backend and retry: each screen recovers
- `?simulateLatencyMs=3000` on the transfer: confirm button disables, double
  tap sends one request, shimmer shows where specified
- Rotate and resize: no overflow at 360 and 430 wide

**Deliverables**
- Debug APK built with the right `--dart-define`
- Screenshots of all seven screens from the **running app**, into `docs/`
- 2–3 minute video: login, dashboard, successful transfer, updated balance,
  history, and one error scenario
- README filled in: prerequisites, setup, base URL, emulator and device,
  test commands, architecture, known limitations
- **AI disclosure section completed** — required by the assignment
- `DECISIONS.md` current
