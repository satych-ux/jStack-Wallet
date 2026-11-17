# jWallet Lite: SPEC.md

Source of truth for the build. Each requirement has an ID. A slice is done only when every ID in it passes and its tests are green.

## 1. Scope

- **In:** Flutter app (Dart) + mock REST backend (Node.js + Express). Login, wallet dashboard, send money, transaction history, transaction details.
- **Out:** real payments, real customer data, cloud deployment, production DB, Add Money (UI stub only), bonus features until all mandatory IDs pass.
- **Decisions:** Node.js + Express backend (preferred stack). In-memory store seeded from `seed.json`, reset on restart. Single process.

## 2. Stack

| Area | Choice |
|---|---|
| Flutter state | Bloc |
| HTTP | Dio (timeouts, interceptors) |
| Navigation | go_router |
| Session storage | flutter_secure_storage |
| UI | Material 3, reusable widgets |
| Flutter tests | flutter_test + mocktail |
| Backend | Node.js 20+, Express |
| Backend tests | node:test + supertest |
| API docs | OpenAPI 3 (`api/openapi.yaml`) + Bruno collection (`api/bruno/`) |

## 3. Architecture

**Backend**
```
backend/
  src/
    app.js            (express app, no listen)
    server.js         (listen on PORT, default 3000)
    routes/           (auth, users, wallet, transactions)
    middleware/       (auth, validate, errorHandler)
    store/            (in-memory store, seeded)
    services/         (transfer logic, idempotency)
  seed.json
  test/
```

**Flutter**
```
lib/
  core/        (dio client, interceptors, Failure, theme, router)
  features/
    auth/        data | domain | presentation
    wallet/      data | domain | presentation
    transfer/    data | domain | presentation
    transactions/ data | domain | presentation
test/
```

Rules:
- No API calls inside widgets.
- Validation logic is pure Dart functions in `domain`.
- The backend is the only owner of balance. The app never computes or edits balance locally.

## 4. API contract

Base path `/api/v1`. All responses use `{ "success": true, "data": ... }`. Errors use `{ "success": false, "error": { "code": "...", "message": "..." } }`.

| Method | Path | Auth | Success | Notes |
|---|---|---|---|---|
| POST | /auth/login | no | 200 | 401 on bad credentials |
| GET | /users/profile | yes | 200 | |
| GET | /wallet/balance | yes | 200 | returns walletId, currency, availableBalance, maskedAccountNumber |
| GET | /transactions | yes | 200 | at least 10 seed items, newest first |
| POST | /transactions/transfer | yes | 200 | requires `Idempotency-Key` header |
| GET | /transactions/:id | yes | 200 | 404 if not found |

Auth: `Authorization: Bearer mock_access_token_123`. Missing or wrong token → 401.

Status codes: 200 success, 400 invalid request data, 401 invalid credentials/token, 404 transaction not found, 409 insufficient balance or idempotency key reused with different payload, 500 unexpected error.

## 5. Backend requirements

| ID | Requirement |
|---|---|
| API-01 | Login returns `accessToken` and user `{id, name, email}` for `demo@jstack.co` / `Demo@123`. |
| API-02 | Wrong credentials return 401 with error code `INVALID_CREDENTIALS`. |
| API-03 | Protected endpoints reject missing or wrong bearer token with 401. |
| API-04 | Balance endpoint returns the current balance from the store, not a constant. |
| API-05 | Transaction list is sorted by `createdAt` descending and has at least 10 seed items with types DEBIT and CREDIT. |
| API-06 | Transfer validates: beneficiaryName required, mobileNumber exactly 10 digits, amount is a number greater than 0 (max 2 decimal places), remarks optional string ≤ 100 chars. Invalid → 400 with field details. |
| API-07 | Transfer rejects amount > available balance with 409 `INSUFFICIENT_BALANCE`. No deduction occurs. |
| API-08 | Successful transfer deducts the amount, creates a DEBIT transaction with status SUCCESS and a unique reference, prepends it to history, and returns `transactionId`, `status`, `amount`, `currency`, `availableBalance`. |
| API-09 | Transfer with a missing `Idempotency-Key` header → 400. |
| API-10 | Same `Idempotency-Key` + identical payload → return the original response, no second deduction, no second transaction. |
| API-11 | Same `Idempotency-Key` + different payload → 409 `IDEMPOTENCY_KEY_REUSED`. |
| API-12 | Balance check and deduction are atomic per wallet: no overdraft under concurrent requests. |
| API-13 | Transaction details return 404 for unknown id. |
| API-14 | Every error response uses the common error shape. Unhandled errors return 500 with no stack trace in the body. |
| API-15 | Optional `?simulateLatencyMs=` query for demo timeouts (default 0). Documented in README. |

## 6. Flutter requirements

### Login (AUTH)
| ID | Requirement |
|---|---|
| AUTH-01 | Login screen shows jWallet Lite branding, email field, password field with show/hide toggle, login button. |
| AUTH-02 | Email format and non-empty password validated before calling the API; inline messages shown. |
| AUTH-03 | Button shows loading indicator and is disabled while the request runs. |
| AUTH-04 | Invalid credentials show an error message; no navigation occurs. |
| AUTH-05 | Successful login stores the token in secure storage and navigates to the dashboard. |
| AUTH-06 | On app start, a stored token is validated via `/users/profile`. Valid → dashboard. Invalid/401 → clear token, show login. |
| AUTH-07 | Logout clears the token and all cached user data, then returns to login. |
| AUTH-08 | Timeouts and connectivity errors show a retry-able error message. |

### Dashboard (WAL)
| ID | Requirement |
|---|---|
| WAL-01 | Shows welcome message with user name and avatar/initials. |
| WAL-02 | Shows available balance, currency (INR), masked account number, fetched from the backend. |
| WAL-03 | Quick actions: Send Money (navigates), Add Money (UI only, shows "coming soon"), Transaction History (navigates). |
| WAL-04 | Shows the latest 5 transactions with amount, type, date, and status. |
| WAL-05 | Pull-to-refresh reloads balance and transactions. |
| WAL-06 | Loading, error (with retry), and empty states are handled. |

### Send Money (TRF)
| ID | Requirement |
|---|---|
| TRF-01 | Form fields: beneficiary name (required), mobile (10 digits), amount (> 0), remarks (optional). |
| TRF-02 | Validation runs before navigating to confirmation. Errors are shown per field. |
| TRF-03 | Confirmation screen shows all details and a Confirm button. |
| TRF-04 | An `Idempotency-Key` (UUID) is generated when the confirmation screen opens and reused for retries of the same attempt. |
| TRF-05 | Confirm is disabled while submitting, so a double tap sends one request. |
| TRF-06 | Success screen shows message, reference, amount, beneficiary, date/time, and "Back to Dashboard". |
| TRF-07 | Failure screen shows the error (insufficient balance, network, timeout, server) with retry and back options. |
| TRF-08 | Insufficient balance is shown as a clear message. The app does not pre-check balance as the source of truth. |
| TRF-09 | After success, balance and transaction data are refetched. The app does not compute the new balance itself. |
| TRF-10 | A timeout followed by retry reuses the same `Idempotency-Key`. |

### Transaction history (TXN)
| ID | Requirement |
|---|---|
| TXN-01 | Lists transactions newest first, each showing reference, name, amount, Credit/Debit, status. |
| TXN-02 | Search by reference or beneficiary name (client-side over fetched list). |
| TXN-03 | Filter by Credit or Debit (plus All). |
| TXN-04 | Empty state when no transactions exist; separate message when filters return none. |
| TXN-05 | Loading and error states with retry. |
| TXN-06 | Tapping a transaction opens details. Details are fetched from `GET /transactions/:id`. |
| TXN-07 | Details show ID, type, amount, beneficiary/sender, date/time, status, remarks if present. |

## 7. Non-functional requirements

| ID | Requirement |
|---|---|
| NFR-01 | No hardcoded balance or transaction data in the Flutter app. |
| NFR-02 | Secrets and tokens are never committed. Base URL comes from `--dart-define`. |
| NFR-03 | Dio timeouts are set (about 10s). Timeout and network errors map to typed Failures. |
| NFR-04 | Rebuild hygiene: balance, history, and auth state are separate providers; `const` widgets where possible; `ListView.builder` for lists; `select` for narrow watches. |
| NFR-05 | Layout works on common Android screen sizes without overflow. |
| NFR-06 | Android emulator base URL is `http://10.0.2.2:3000`. Debug cleartext HTTP is allowed and documented. |

## 8. Testing

Required (mandatory):
- TST-01: Login form validation (AUTH-02).
- TST-02: Transfer amount validation (TRF-01/02).
- TST-03: Insufficient balance handled in the transfer flow (TRF-07/08).
- TST-04: Successful transfer state update (TRF-06/09).

Backend (add):
- TST-05: Idempotency — same key, same payload → one deduction (API-10).
- TST-06: Idempotency — same key, different payload → 409 (API-11).
- TST-07: Concurrency — parallel transfers never overdraft (API-12).
- TST-08: Auth required on protected endpoints (API-03).

## 9. Error handling map

| Scenario | Backend | App behaviour |
|---|---|---|
| Bad credentials | 401 INVALID_CREDENTIALS | Error message on login |
| Bad transfer data | 400 VALIDATION_ERROR + fields | Field errors shown |
| Insufficient balance | 409 INSUFFICIENT_BALANCE | Failure screen, balance unchanged |
| Key reused, different payload | 409 IDEMPOTENCY_KEY_REUSED | Failure screen (should not happen in normal flow) |
| Transaction not found | 404 | Details error with back |
| Server error | 500 | Generic failure with retry |
| Timeout / no network | none | Typed timeout/network failure with retry |

## 10. Deliverables checklist

- [ ] GitHub repo with `app/`, `backend/`, `api/`, `README.md`, `DECISIONS.md`, `SPEC.md`
- [ ] README: prerequisites and Flutter version, dependencies, app setup, backend setup, base URL config, emulator/device connectivity, test commands, architecture decisions, known limitations, AI-generated components
- [ ] API collection (Bruno) and OpenAPI spec
- [ ] Debug or release APK
- [ ] Screenshots of all 7 required screens
- [ ] 2–3 min demo video: login, dashboard, successful transfer, updated balance, history, one error scenario

## 11. Definition of done (per slice)

1. Every ID in the slice passes manually.
2. Its tests are green.
3. `flutter analyze` and backend lint are clean.
4. Every file in the slice can be explained by the author.
5. `DECISIONS.md` updated with any choice made.
6. AI-generated parts logged in the README draft.

## 12. Slice order

0. Backend contract and server (API-01 to API-15, TST-05 to TST-08)
1. Auth (AUTH-*)
2. Dashboard (WAL-*)
3. Transfer (TRF-*, TST-01 to TST-04)
4. History and details (TXN-*)
5. Polish: error/empty/loading audit, README, video