# jWallet Lite

A lightweight digital wallet built for the jStack Flutter Developer assignment: a Flutter mobile app backed by a self-hosted mock REST API.

- `app/` — Flutter application
- `backend/` — Node.js + Express mock REST API
- `api/` — API collection and OpenAPI specification
- `SPEC.md` — acceptance criteria driving the build
- `DECISIONS.md` — architecture decisions and their rationale

---

## Quick start

Two terminals. The backend must be running before the app launches.

**Terminal 1 — backend**

```bash
cd backend
npm install
npm start            # listens on 0.0.0.0:3000
```

**Terminal 2 — app**

```bash
cd app
flutter pub get
flutter devices      # note the id of the emulator or phone you want
```

Then pick the line that matches your target:

```bash
# Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1

# Physical Android device (replace the IP — see "Finding your IP" below)
flutter run --dart-define=API_BASE_URL=http://192.168.1.36:3000/api/v1

# iOS simulator
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

Add `-d <device-id>` if more than one device is connected.

Sign in with `demo@jstack.co` / `Demo@123`.

> **`--dart-define` is required.** The app checks for it at launch and stops
> with "API_BASE_URL is not set" rather than failing later with a confusing
> network error. The value is baked in at build time, so a hot restart will not
> pick up a change — stop the app and run `flutter run` again.

---

## Prerequisites

| Tool | Version |
|---|---|
| Flutter | 3.47 or newer (developed on 3.47.9, stable) |
| Dart | 3.13 (ships with Flutter) |
| Node.js | 20 or newer (developed on 25.2.1) |
| Android | Android Studio with an emulator, or a phone with USB debugging. Tested on an API 36 (Android 16) emulator and a physical Android phone on the same Wi-Fi |
| iOS | Not tested. It should run on the simulator with `http://localhost:3000/api/v1`; a real iPhone needs Xcode signing |

Nothing else is needed: no accounts, keys or `.env` files. The only value you
supply is the backend URL (below), and for a physical phone that means your
computer's **IP address** on the local network, not its MAC address.

## Backend setup

```bash
cd backend
npm install
npm start          # http://localhost:3000, base URL http://localhost:3000/api/v1
npm test           # 166 tests, about 2 seconds
```

- **Port:** `PORT=4000 npm start` to change it. The server binds to `0.0.0.0`, so an emulator (`10.0.2.2`) or a phone on the same network can reach it.
- **State:** held in memory, seeded from `backend/seed.json` on boot (one user, a balance of ₹25,450.75, 12 transactions). **Every restart resets it**, which is intentional for a mock. Money is stored as integer paise and sent as rupees.
- **Auth:** log in with the demo credentials below; every other endpoint needs `Authorization: Bearer mock_access_token_123`.
- **Errors:** always `{ "success": false, "error": { "code", "message", "fields"? } }`. `fields` appears only on `VALIDATION_ERROR` and names each bad field.

Health check:

```bash
curl http://localhost:3000/api/v1/health
```

### Reproducing the transfer cases

Set these once in your shell:

```bash
B=http://localhost:3000/api/v1
AUTH='Authorization: Bearer mock_access_token_123'
S='-w \n[HTTP %{http_code}]\n'   # print the status code after each response
BODY='{"beneficiaryName":"Rahul Sharma","mobileNumber":"9876543210","amount":1500}'
```

**Idempotency.** Send the same transfer twice with the same key:

```bash
KEY=$(uuidgen)
curl -s $S -H "$AUTH" -H 'Content-Type: application/json' -H "Idempotency-Key: $KEY" -d "$BODY" $B/transactions/transfer
curl -s $S -H "$AUTH" -H 'Content-Type: application/json' -H "Idempotency-Key: $KEY" -d "$BODY" $B/transactions/transfer
curl -s $S -H "$AUTH" $B/wallet/balance
```

Both transfers return the same `transactionId`, and the balance drops by ₹1,500 once. Reusing the key with a different body returns `409 IDEMPOTENCY_KEY_REUSED`, and leaving the header out returns `400 IDEMPOTENCY_KEY_REQUIRED`. Only a successful transfer locks its key; after a 400 or a 409 the same key can be retried.

**Insufficient balance.** Ask for more than the wallet holds:

```bash
curl -s $S -H "$AUTH" -H 'Content-Type: application/json' -H "Idempotency-Key: $(uuidgen)" \
  -d '{"beneficiaryName":"Rahul Sharma","mobileNumber":"9876543210","amount":99999}' $B/transactions/transfer
curl -s $S -H "$AUTH" $B/wallet/balance
```

The transfer returns `409 INSUFFICIENT_BALANCE`, and the balance and history are unchanged.

**Slow responses (timeout demo).** Add `?simulateLatencyMs=<ms>` to any request (default 0, capped at 30000; anything but plain digits counts as 0). The request is handled at once and only the response is held back. So a slow transfer has already deducted, and stored its key, by the time a client gives up. A retry with the same key then gets the stored response, with no second deduction:

```bash
KEY2=$(uuidgen)
curl -s $S -m 1 -H "$AUTH" -H 'Content-Type: application/json' -H "Idempotency-Key: $KEY2" -d "$BODY" "$B/transactions/transfer?simulateLatencyMs=5000"   # gives up after 1s
curl -s $S      -H "$AUTH" -H 'Content-Type: application/json' -H "Idempotency-Key: $KEY2" -d "$BODY" $B/transactions/transfer                             # the stored 200
```

The first request prints `[HTTP 000]`: curl gave up before any response came. The second returns the stored transfer (the same `transactionId` the first one created), and the balance dropped once. `uuidgen` ships with macOS and most Linux distributions; any unique string works as a key.

## Running the app in detail

### 1. Start the backend first

The app has no offline mode and no bundled data — every screen loads from the
API. Start `npm start` in `backend/` and leave it running.

### 2. Choose the base URL for your target

The base URL is injected at build time with `--dart-define`; nothing is
hardcoded and no secrets are committed.

| Target | `API_BASE_URL` |
|---|---|
| Android emulator | `http://10.0.2.2:3000/api/v1` |
| Physical Android device | `http://<your-computer-LAN-IP>:3000/api/v1` |
| iOS simulator | `http://localhost:3000/api/v1` |

An Android emulator cannot see `localhost` — that address is the emulator
itself. `10.0.2.2` is the emulator's alias for the host machine.

### 3. Find your device id

```bash
flutter devices
```

The id is the second column: a serial such as `RZ8M802ABCD` for a phone,
`emulator-5554` for an emulator. Pass it with `-d`, or omit `-d` entirely when
only one device is connected.

If a connected phone does not appear, run `adb devices`. A line reading
`unauthorized` means the USB-debugging prompt on the phone has not been
accepted yet.

### Running on a physical device

Enable USB debugging once: Settings → About phone → tap **Build number** seven
times, then Settings → Developer options → **USB debugging** on. Plug the phone
in and accept the "Allow USB debugging" prompt.

**The phone and the computer must be on the same Wi-Fi network.** The phone
reaches the backend over the local network, so a computer on Wi-Fi and a phone
on mobile data will not connect. Corporate or guest networks that isolate
clients from each other will also block it; a phone hotspot that the computer
joins is the usual workaround.

#### Finding your IP

```bash
# macOS
ipconfig getifaddr en0          # Wi-Fi; try en1 if that returns nothing

# Linux
hostname -I | awk '{print $1}'

# Windows
ipconfig                        # use the IPv4 Address of your Wi-Fi adapter
```

Check the phone can reach it before launching — open
`http://<your-ip>:3000/api/v1/health` in the phone's browser. A JSON response
means you are set. Nothing at all usually means a firewall on the computer is
blocking port 3000, or the two devices are on different networks. On macOS,
allow incoming connections for `node` if the firewall asks.

The IP can change when the computer reconnects to Wi-Fi. If the app suddenly
can't reach the server, check the IP again and relaunch with the new one.

The backend already binds to `0.0.0.0`, so no change is needed there.

### Demo credentials

| Email | Password |
|---|---|
| `demo@jstack.co` | `Demo@123` |

### Running from an IDE

The Run button does not pass `--dart-define`, so add it to the run
configuration once:

- **VS Code** — in `.vscode/launch.json`, add to your configuration:

  ```json
  "args": ["--dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1"]
  ```

- **Android Studio** — Run → Edit Configurations → Additional run args:

  ```
  --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
  ```

### Troubleshooting

| Symptom | Cause |
|---|---|
| "API_BASE_URL is not set" at launch | `--dart-define` missing; a hot restart will not fix it, relaunch |
| Login spins then fails on an emulator | Used `localhost` instead of `10.0.2.2` |
| Login spins then fails on a phone | Different networks, wrong IP, or a firewall on port 3000 |
| Balance or history "jumped back" after a backend restart | State is in memory and resets to the seed (₹25,450.75); the session itself stays valid |

## Running tests

```bash
cd backend && npm test        # 166 tests, all passing
cd app && flutter analyze     # no issues
cd app && flutter test
```

Status of the Flutter tests, stated plainly: the theme, widget, validator,
network-core (W0) and auth (W1) tests were run and passed during the build.
The tests added later (wallet, transactions, the debug panel, and the
`TransferBloc` tests for insufficient balance and a successful transfer) were
written but not run, at the author's choice; the wiring was verified instead by
driving the running app against the live backend. Two widget-level files
(`app_test.dart`, `router_test.dart`) were removed because they hung inside
`flutter test` (an `AuthBloc.close()` that never completes under the test
clock). See `DECISIONS.md` row 151.

## Building the APK

```bash
cd app

# for an emulator
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1

# for a physical device, use your computer's LAN IP
flutter build apk --debug --dart-define=API_BASE_URL=http://192.168.1.36:3000/api/v1

# output: build/app/outputs/flutter-apk/app-debug.apk
```

The base URL is fixed when the APK is built, so a prebuilt APK only works
against the target it was built for. Install with
`adb install -r build/app/outputs/flutter-apk/app-debug.apk`.

## Architecture

Feature-first folders, each split into three layers:

```
app/lib/
  core/              theme, shared widgets, router, DI, network, errors, debug panel
  features/
    auth/            login, session (secure storage), AuthBloc
    wallet/          dashboard: profile, balance, recent activity (WalletBloc)
    transactions/    history and details (TransactionsBloc, TransactionDetailsBloc)
    transfer/        send money, confirm, result (TransferBloc)
      data/          models (json_serializable), remote data sources, repository impls
      domain/        entities, repository interfaces, validators (pure Dart)
      presentation/  blocs, view models, screens, widgets
```

- **State management: Bloc.** One bloc per feature; screens read only what they
  need (the dashboard has one `BlocSelector` per section, so a section rebuilds
  only when its own data changes).
- **Network:** one `Dio`, an auth interceptor (bearer token; a 401 for the
  current token signs out), typed `Failure`s, and repositories that return
  `Result<T>` instead of throwing.
- **Money:** the backend owns the balance. The app formats amounts and never
  adds, subtracts or caches a balance; after a transfer the dashboard reloads it.
- **Transfers:** each attempt carries an `Idempotency-Key`; a retry of the same
  attempt reuses it, so a timeout can never charge twice.
- **Navigation:** go_router with seven flat routes and an auth guard driven by
  `AuthBloc`.

See `DECISIONS.md` for the reasoning behind each choice.

### Debug panel (for reviewers)

Debug builds show a small **bug button** on the left edge of every screen. It opens options that make the backend produce its real error paths:

| Option | What you'll see |
|---|---|
| Slow server (timeout) | The transfer goes through on the server but the app times out ("NOT CONFIRMED"). **Try again** reuses the same Idempotency-Key and returns the original result: one deduction. |
| Reuse the last transfer's key | 409 `IDEMPOTENCY_KEY_REUSED`, nothing debited (make one successful transfer first) |
| Drop the Idempotency-Key | 400, nothing debited |
| Offline | Every screen shows its error state with Retry until switched off |
| Expire my session | The next request gets a real 401 and the app returns to login |

Transfer options apply to the next transfer only. Insufficient balance and form validation need no switch: send more than the balance, or enter `10.123` as the amount. Other builds can show the panel with `--dart-define=DEBUG_PANEL=true`; release builds never include it.

## API documentation

- **`api/openapi.yaml`** is the contract: all six endpoints plus health, with request and response schemas, every status code and error code, and the idempotency rules.
- **`api/bruno/`** is a [Bruno](https://www.usebruno.com/) collection. Open the folder in Bruno and pick the `local` environment, or run it from the command line against a freshly started backend: `npx @usebruno/cli run -r --env local` inside `api/bruno/`. It covers every endpoint plus the 401, 404, 409 and 400 cases. The `4 Transfer` folder walks through a transfer, a same-key retry (same `transactionId`, no second deduction), a reused key with a different payload (409), insufficient balance (409, nothing deducted) and a slow response. Each request carries tests (20 in all).

## Known limitations

- Backend state is in-memory and resets on restart.
- The backend accepts only the fixed token `mock_access_token_123`, with no expiry. The demo password is stored in plain text in `seed.json`.
- Idempotency keys are kept in memory for the life of the process, with no expiry, and are global rather than per user (there is one user).
- A rejected transfer (400 or 409) leaves no trace in the history. FAILED and PENDING rows exist only in the seed data.
- No endpoint creates a credit; seeded credits are the only ones.
- `?simulateLatencyMs=` is always available, to anyone, on every endpoint (it is a demo server). It delays JSON responses only: a browser's CORS preflight and the bare 400/431 replies Node itself sends for malformed requests or oversized headers are not delayed.
- The Bruno collection's first balance check expects a freshly started server; a second run against the same server fails that one check.
- Transaction search and filtering are applied client-side over the fetched list.
- Add Money is a UI stub, as the assignment specifies.
- Single backend process; concurrency safety relies on that.
- Some Flutter tests were not run, and two widget-level test files were removed (see "Running tests").
- iOS was not tested.
- No `BlocObserver` is registered, so bloc transitions are not logged.

## AI-assisted development disclosure

This project was built with an AI coding assistant. The backend, the Flutter
app, the tests, the API collection and much of this README were generated with
it, task by task, following `SPEC.md`, `DESIGN.md` and the task files; each
task was reviewed in a separate critic pass before the next began. The log
below lists what was generated in each task. Every non-obvious choice is
recorded with its reason in `DECISIONS.md`.

**Author's confirmation:** _(to be written by the author: that all submitted
code has been reviewed and can be explained)_

AI-generated so far (log, kept up to date per task):

- T0: `core/theme/` (colours, text styles, spacing, theme), `core/widgets/brand_mark.dart`, the TEMPORARY domain/data stubs for all four features, and `test/theme_test.dart`. Values transcribed from `DESIGN.md`.
- T1: every shared widget in `core/widgets/` and `core/widgets/shimmer/`, the component text styles added to `app_text_styles.dart`, and the widget tests in `test/core/widgets/`.
- T2: `core/router/` (`app_routes.dart`, `app_router.dart`, `not_found_screen.dart`, the TEMPORARY `route_placeholder.dart`) and `test/core/router/router_test.dart`.
- T3: `features/auth/presentation/` (login screen, demo-credentials card), `features/auth/domain/validators/login_validators.dart`, and their tests in `test/features/auth/`.
- T4: `core/presentation/section.dart`, `features/wallet/presentation/` (dashboard screen, header, recent activity, view models) and `test/features/wallet/dashboard_screen_test.dart`.
- T5: `features/transfer/presentation/` (send money screen, balance strip, `TransferDraft`), `features/transfer/domain/validators/transfer_validators.dart`, and their tests in `test/features/transfer/`.
- T6: `features/transfer/presentation/screens/confirm_transfer_screen.dart`, `models/confirmation_view.dart`, and `test/features/transfer/confirm_transfer_screen_test.dart`.
- T7: `features/transfer/presentation/screens/transfer_result_screen.dart`, `models/transfer_result_view.dart`, the `header` slot on `DetailCard`, and `test/features/transfer/transfer_result_screen_test.dart`.
- T8: `features/transactions/presentation/` (history screen, search field, `history_view.dart` with `groupHistory`), and `test/features/transactions/`.
- T9: `features/transactions/presentation/screens/transaction_details_screen.dart`, `models/transaction_details_view.dart`, the foreground-border fix in `DetailCard`, its shimmer and the text-field frame, and `test/features/transactions/transaction_details_screen_test.dart`.
- App wiring: `main.dart` (`JWalletApp`), `onLoginSubmitted` and the Send money → Confirmation hop in `app_router.dart`, `TransferAttempt`, `ConfirmationView.fromDraft`, and `test/app_test.dart`.
- Sample-data wiring (TEMPORARY): `core/router/temporary_fake_wiring.dart` and its use in `app_router.dart` and `main.dart`.
- Backend B0: `api/openapi.yaml`, `backend/seed.json`, `backend/src/{app,server}.js`, `src/store/index.js`, `src/models/appError.js`, `src/middleware/errorHandler.js`, `src/routes/health.js`, and the tests in `backend/test/`.
- Backend B1: `src/routes/auth.js`, `src/routes/users.js`, `src/middleware/auth.js`, `src/models/user.js`, the demo password in `seed.json`, and `backend/test/auth.test.js`.
- Backend B2: `src/routes/wallet.js`, `src/routes/transactions.js`, `src/models/{money,wallet,transaction}.js`, and `backend/test/wallet-transactions.test.js`. B2 critic fixes: `src/middleware/cors.js`, the integer guard in `money.js`, the 4xx split in `errorHandler.js`, ETag off in `app.js`, and `backend/test/money.test.js`.
- Backend B3: `src/services/transferValidation.js`, `src/services/transfer.js`, the transfer route in `src/routes/transactions.js`, and `backend/test/transfer.test.js`.
- Backend B4: `src/services/idempotency.js`, `toTransferResponse` in `src/models/transaction.js`, the idempotency map in `src/store/index.js`, the reworked transfer route, and `backend/test/idempotency.test.js`. B4 critic fixes: the shared `isNoRemarks` rule, the comma check in `requireKey`, and the added idempotency tests.
- Backend B5: `backend/test/concurrency.test.js` (no production code changed). B5 critic fixes: the connection warm-up and the tightened assertions in the same file.
- Backend B6: `src/middleware/latency.js`, `backend/test/latency.test.js`, `backend/test/errorShape.test.js`, the Bruno collection in `api/bruno/`, and the backend sections of this README. B6 critic fixes: the send guards and digits-only parsing in `latency.js`, and the reworked timing tests.
- Wiring W0: `scripts/capture-fixtures.sh`, `app/lib/core/config/app_config.dart`, `core/error/{failure,api_error,failure_mapper}.dart`, `core/network/{dio_client,auth_interceptor,token_store,session_expired_signal}.dart`, `core/di/injector.dart`, the `configureDependencies()` call in `main.dart`, and the tests in `app/test/core/{error,network,di}/` plus `test/helpers/fixtures.dart`. The fixtures in `app/test/fixtures/` were captured from the running backend, not written. W0 critic fixes: the all-or-nothing capture script with five more fixtures, the public-path and once-only 401 handling in `auth_interceptor.dart`, and the added interceptor, mapper and injector tests.
- Wiring W1–W4: the auth, wallet, transactions and transfer data layers (models, data sources, repositories), `core/error/{result,guard}.dart`, `core/network/envelope.dart`, `core/presentation/{formatters,failure_message}.dart`, `AuthBloc`, `WalletBloc`, `TransactionsBloc`, `TransactionDetailsBloc`, `TransferBloc`, `AvailableBalanceCubit`, the router and `main.dart` rewiring, the avatar sign-out, and the tests under `test/features/{auth,transfer}/` and `test/helpers/`.
- Debug panel: `app/lib/core/debug/{debug_settings,debug_interceptor,debug_panel}.dart`, its wiring in `injector.dart` and `main.dart`, and the `scrim` colour.

Tooling used: Claude Code (Anthropic), with the Dart and Flutter MCP tools for
analysis and hot reload, and the Bruno CLI to run the API collection.
