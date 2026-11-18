# jWallet Lite

A lightweight digital wallet built for the jStack Flutter Developer assignment: a Flutter mobile app backed by a self-hosted mock REST API.

- `app/` — Flutter application
- `backend/` — Node.js + Express mock REST API
- `api/` — API collection and OpenAPI specification
- `SPEC.md` — acceptance criteria driving the build
- `DECISIONS.md` — architecture decisions and their rationale

---

## Prerequisites

| Tool | Version |
|---|---|
| Flutter | TODO: output of `flutter --version` |
| Dart | TODO |
| Node.js | 20 or newer (developed on 25.2.1) |
| Android | TODO: emulator API level / device used |

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

## Application setup

```bash
cd app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

### API base URL configuration

The base URL is injected at build time with `--dart-define`; nothing is hardcoded and no secrets are committed.

| Target | Value |
|---|---|
| Android emulator | `http://10.0.2.2:3000/api/v1` |
| Physical Android device | `http://<your-machine-LAN-IP>:3000/api/v1` |
| iOS simulator | `http://localhost:3000/api/v1` |

The emulator reaches the host machine at `10.0.2.2`, not `localhost`. Debug builds permit cleartext HTTP so the local backend is reachable; release builds would require HTTPS.

For a physical device, the phone and the computer must be on the same network, and the backend must bind to `0.0.0.0`.

### Demo credentials

| Email | Password |
|---|---|
| `demo@jstack.co` | `Demo@123` |

## Running tests

```bash
cd backend && npm test
cd app && flutter test
cd app && flutter analyze
```

## Building the APK

```bash
cd app
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
# output: build/app/outputs/flutter-apk/app-debug.apk
```

## Architecture

TODO: layering summary (presentation / domain / data), state management choice, folder map.

See `DECISIONS.md` for the reasoning behind each choice.

## API documentation

- **`api/openapi.yaml`** is the contract: all six endpoints plus health, with request and response schemas, every status code and error code, and the idempotency rules.
- **`api/bruno/`** is a [Bruno](https://www.usebruno.com/) collection. Open the folder in Bruno and pick the `local` environment, or run it from the command line against a freshly started backend: `npx @usebruno/cli run -r --env local` inside `api/bruno/`. It covers every endpoint plus the 401, 404, 409 and 400 cases. The `4 Transfer` folder walks through a transfer, a same-key retry (same `transactionId`, no second deduction), a reused key with a different payload (409), insufficient balance (409, nothing deducted) and a slow response. Each request carries tests (20 in all).

## Known limitations

TODO. Candidates to document:
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

## AI-assisted development disclosure

TODO: list the components that were substantially AI-generated, and confirm that all submitted code has been reviewed and is explainable.

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

Tooling used: TODO.
