# Backend build — task decomposition

Mock REST API, Node.js + Express, in `backend/`. Contract and acceptance IDs
live in `SPEC.md` sections 4, 5 and 9.

## How to run this

One task per Claude Code session. A task is done only when all of these hold:

1. `cd backend && npm test` passes
2. Every acceptance ID in the task verifies by hand with the Bruno collection or curl
3. No `await` sits between reading and writing the balance
4. You can explain every file

Critic pass after each task, fresh session:
> Review the diff for task BN against SPEC.md sections 4, 5 and 9. List every
> endpoint, status code or field name that differs from the contract. List
> edge cases not handled. Fix nothing.

---

## Decisions to settle before B1

Each has a recommended default. Accept or override, then record the choice in
`DECISIONS.md`. If Claude Code raises an edge case not listed here, answer it
and add it to this list.

| # | Question | Recommended default |
|---|---|---|
| 1 | Money representation | **Store integer paise internally**, format to 2dp only on output. Floating-point rupees will produce `23950.749999` after a few transfers. This is the single most defensible engineering choice in the whole backend. |
| 2 | JSON number formatting | JSON cannot preserve `1500.00` — it serialises as `1500`. Send amounts as **numbers** per the spec and let Flutter format to 2dp. Do not send strings; it breaks the contract the spec shows. |
| 3 | Token | Login returns the literal `mock_access_token_123` from the spec. Middleware accepts **only** that value. No expiry, no signing. |
| 4 | Where the idempotency key is reserved | Reserve the key **before** validating or deducting, so a second request with the same key can never interleave. Store `{payloadHash, status, response}`. |
| 5 | Same key, different payload | `409 IDEMPOTENCY_KEY_REUSED`. Already in SPEC.md as API-11. |
| 6 | Missing `Idempotency-Key` header | `400`. Already API-09. |
| 7 | Are failed transfers recorded in history? | **No.** The spec says add to history on success only. A rejected transfer leaves no trace beyond the error response. Document it as a known limitation. |
| 8 | Then where do FAILED and PENDING rows come from? | **Seed them.** `seed.json` must contain at least one `FAILED` and one `PENDING` transaction, or the UI's status states can never be demonstrated in the video. |
| 9 | Credit transactions | Seeded only. No endpoint creates a credit. |
| 10 | Mobile validation | `^[0-9]{10}$`. Do not constrain the leading digit; the spec says "valid 10-digit number" and nothing more. |
| 11 | Remarks | Optional, string, max 100 characters. |
| 12 | Amount precision | Reject more than 2 decimal places with `400`. |
| 13 | Transaction id generation | Seed `TXN10001`–`TXN10012` (API-05 needs 10 or more). New ids continue from the highest seeded id: `TXN10013`, `TXN10014`, … Same shape as the seeds. |
| 14 | Transfer to the wallet's own number | Not addressed by the spec. Allow it. Do not invent rules the graders did not ask for. |
| 15 | Maximum transfer amount | None beyond the available balance. |
| 16 | Server binding | `0.0.0.0`, not `localhost`, so a physical Android device on the same network can reach it. |
| 17 | CORS | Enable permissively. The app does not need it, but Bruno and a browser do, and it costs one line. |
| 18 | Persistence | In-memory, seeded on boot, resets on restart. Documented as a limitation. |
| 19 | Starting balance | **₹25,450.75** (`2545075` paise) in `seed.json`. B5's concurrency test is written against it. The app's sample data (₹24,850.75) is TEMPORARY and does not bind the backend. |

---

## B0 — Contract and skeleton

**Build**
- `api/openapi.yaml` — all six endpoints, request and response schemas, every
  status code from SPEC.md section 9
- `backend/seed.json` — 10+ transactions, descending by `createdAt`, including
  at least one `FAILED` and one `PENDING`, and a mix of `DEBIT` and `CREDIT`
- `backend/src/app.js` (express app, no `listen`), `src/server.js` (listen on
  `PORT`, default 3000, bind `0.0.0.0`)
- `src/store/index.js` — in-memory state seeded from `seed.json`, balance held
  as integer paise
- `src/middleware/errorHandler.js` — one error shape, no stack traces in the body
- `GET /api/v1/health`

**Tests**
- Health returns 200
- An unknown route returns 404 in the standard error shape
- A thrown error returns 500 with no `stack` field in the body
- The store seeds 10 or more transactions, sorted newest first
- The seed contains at least one FAILED and one PENDING

---

## B1 — Auth

**Build** `POST /api/v1/auth/login`, `src/middleware/auth.js`,
`GET /api/v1/users/profile`.

**Tests** — API-01, API-02, API-03
- Correct credentials return 200 with `accessToken` and `user {id, name, email}`
- Wrong password returns 401 `INVALID_CREDENTIALS`
- Unknown email returns 401 with the same code and message (do not leak which
  field was wrong)
- Missing email or password returns 400
- `/users/profile` with no `Authorization` header returns 401
- With `Bearer wrong` returns 401
- With the valid token returns 200 and the user

---

## B2 — Wallet and transaction reads

**Build** `GET /wallet/balance`, `GET /transactions`, `GET /transactions/:id`.

**Tests** — API-04, API-05, API-13
- Balance returns `walletId`, `currency`, `availableBalance`, `maskedAccountNumber`
- `availableBalance` is a number with at most 2 decimal places
- Balance reflects the store, not a constant: deduct in the store, read again, it changed
- All three endpoints return 401 without a token
- Transaction list returns 10 or more, sorted by `createdAt` descending
- `GET /transactions/TXN10001` returns that transaction
- `GET /transactions/NOPE` returns 404

---

## B3 — Transfer, happy path and validation

**Build** `POST /transactions/transfer` — validation, balance check, deduct,
record, respond. Idempotency comes next; stub the header check for now.

**Carried from the B2 critic pass:** the list stays newest first only because
transfers are prepended (DECISIONS row 82). Add a test that a transfer lands
at the head of `GET /transactions`, and store `amountPaise` as an integer
(`toRupees` throws otherwise).

**Tests** — API-06, API-07, API-08
- Valid transfer returns 200 with `transactionId`, `status`, `amount`,
  `currency`, `availableBalance`
- The returned balance equals the old balance minus the amount
- A new DEBIT transaction appears at the head of the list with status SUCCESS
- Missing beneficiary, 9-digit mobile, 11-digit mobile, non-numeric mobile,
  amount `0`, negative amount, non-numeric amount, 3-decimal amount — each 400
  with the offending field named
- Remarks absent is valid; remarks over 100 characters is 400
- Amount one paisa above the balance returns 409 `INSUFFICIENT_BALANCE`
- After that 409 the balance is unchanged and no transaction was added

---

## B4 — Idempotency

**Build** `src/services/idempotency.js` and wire it into the transfer route.

**Carried from the B3 critic pass:**
- Build the 200 body in one small function, so the stored replay is exactly
  the first answer, including the balance at that moment.
- `validateTransfer` throws on a 400; with the key reserved first, release
  the key in that path.
- Decide whether the payload comparison uses the raw body or the cleaned
  values (raw is simpler), and whether a 409 is stored or releases the key.

**Tests** — API-09, API-10, API-11
- No `Idempotency-Key` header returns 400
- Same key, identical payload, sent twice: both return 200 with the **same**
  `transactionId`, the balance drops **once**, and the list gains **one** row
- Same key, different payload returns 409 `IDEMPOTENCY_KEY_REUSED`
- Different keys with identical payloads both succeed and deduct twice
- A key whose first request failed validation does not block a corrected retry
  with the same key

---

## B5 — Concurrency and money safety

**Build** integer-paise arithmetic end to end, and make the read-check-write
of the balance one synchronous block.

**Tests** — API-12
- 10 parallel transfers of ₹5,000 against a ₹25,450.75 balance: at most 5
  succeed, the rest return 409, and the final balance is never negative
- The successful amounts plus the final balance equal the starting balance
- 5 parallel requests sharing one idempotency key produce exactly one deduction
- 1000 sequential ₹0.01 transfers leave the balance exactly ₹10.00 lower than
  it started, with no floating-point drift

---

## B6 — Finish

**Carried from the B4 critic pass:**
- Do **not** make the transfer handler `async` to add the delay. In Express 4
  a rejected promise never reaches the error handler, so every 400/409 would
  hang the request (and can crash Node). Delay with `setTimeout` around the
  final `res.json`, or with a middleware placed before the router.
- The delay must come after `remember`, never between the key lookup and it
  (DECISIONS row 104).
- Decide whether replays and error responses are delayed too. If a retry
  keeps `?simulateLatencyMs=` and the app's timeout is shorter, every retry
  times out although the money already moved.

**Build**
- Verify every error path returns the shared shape and the right code
- `?simulateLatencyMs=` support (API-15), default 0
- `api/bruno/` collection covering all six endpoints plus the 401, 404 and 409 cases
- The backend half of `README.md`: setup, run, base URL, reset-on-restart,
  how to reproduce the idempotency and insufficient-balance cases

**Tests** — API-14
- Every error response carries `success: false` and `error {code, message}`
- `simulateLatencyMs=500` delays the response by roughly 500ms

---

## After the backend

Flutter data and domain, one feature at a time, deleting a
`fake_*_repository.dart` as each real one lands.

**From the B4 critic pass:** a 400 can arrive without `fields` (missing or
doubled `Idempotency-Key`). The app's 400 mapping must handle that, not
assume a field map.

**Do not forget the gap recorded in SPEC.md section 8.** TST-03 and TST-04 are
currently widget tests only. The transfer wiring slice is not done until
`TransferBloc` has tests against a mocked repository for the
insufficient-balance failure and the successful-transfer state update.
