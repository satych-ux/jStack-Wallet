---
name: jwallet-lite-build
description: Build rules for the jStack jWallet Lite Flutter assignment: Bloc state, Dio, go_router, mock Express backend, idempotent transfers, and the graded acceptance criteria.
---

# jWallet Lite build rules

Applies to the jStack Round-1 Flutter assignment. `SPEC.md` in the repo root holds the acceptance IDs; this file holds how to build against them. When the two disagree, `SPEC.md` wins.

## Non-negotiables

These are the rules the rubric fails you on. Check every diff against them.

1. **The backend owns the balance.** The app never computes, decrements, or caches an authoritative balance. After a successful transfer, refetch or use the `availableBalance` the server returned.
2. **No static JSON in the app** as a substitute for the backend. All wallet and transaction data arrives over HTTP.
3. **Every transfer carries an `Idempotency-Key`.** Generated once when the confirmation screen opens, reused across retries of that same attempt, discarded only when the user starts a new transfer.
4. **Seven distinct screens:** Login, Dashboard, Send Money, Transfer Confirmation, Transfer Result, Transaction History, Transaction Details. Confirmation and Result do not merge.
5. **Four mandatory tests must exist and pass:** login form validation, transfer amount validation, insufficient-balance handling, successful-transfer state update.
6. **Every file must be explainable by the author.** If generated code is longer or cleverer than needed, regenerate it simpler.

## State management: Bloc

- One bloc per feature: `AuthBloc`, `WalletBloc`, `TransferBloc`, `TransactionsBloc`. Do not funnel unrelated state through one bloc, it defeats selective rebuilds.
- **Sealed state classes** with `Equatable` and `const` constructors. Exhaustive `switch` in builders; no `if (state is ...)` chains and no `default:` clause, so a new state becomes a compile error.
- **Atomic state:** one state class per bloc holding immutable fields, updated via `copyWith`. Prefer this over many small state subclasses when fields change independently.
- **`BlocSelector`** for any widget that depends on a single field (balance text, button enabled flag, filter chip). `BlocBuilder` only when the widget genuinely needs the whole state.
- **`BlocListener` for side effects only**: navigation, snackbars, dialogs. Never rebuild UI from a listener. Use `BlocConsumer` only where a widget truly both rebuilds and reacts.
- **Event transformers** (`bloc_concurrency`):
  - `droppable()` on `TransferSubmitted`. This is how a double tap sends one request. Pair it with a disabled button, do not rely on the button alone.
  - `restartable()` or a debounce transformer on transaction search.
  - Default sequential elsewhere.
- **Blocs stay pure:** event in, state out. No `BuildContext`, no navigation, no direct Dio calls. Repositories only.
- `BlocProvider` lazy by default; set `lazy: false` only when a bloc must fetch before first frame.
- Register a `BlocObserver` in `main()`. It doubles as transition evidence while recording the demo video.

## Rebuild discipline

UI may be generated, but structure it so rebuild scope stays controllable:

- Leaf widgets small and `const` wherever the constructor allows.
- No logic in `build()`: no formatting loops, no filtering, no sorting. Derive in the bloc or in a pure helper.
- `ListView.builder` for transaction lists; never a `Column` of mapped children.
- Wrap only the smallest subtree that changes in a `BlocSelector`, not the whole `Scaffold`.
- Verify with DevTools: enable "Highlight repaints" and check that a balance refresh does not repaint the transaction list.

## Routing

- `go_router`, with route path strings and route names in their own file. No string literals at call sites.
- Auth guard via `redirect`: unauthenticated users land on login; authenticated users are bounced off login. Drive it from `AuthBloc` through a `refreshListenable`.
- Pass identifiers as path params (`/transactions/:id`); pass prepared objects via `extra` only between confirmation and result, and refetch details by id rather than trusting `extra`.
- Flat routes are sufficient. No nested shells, no deep linking, no preloading.

## Networking

- Single configured `Dio` instance: base URL from `--dart-define`, connect and receive timeouts around 10s.
- **Auth interceptor** attaches the bearer token; on 401 it clears the session and signals `AuthBloc` to log out.
- **Models** via `json_serializable`. No hand-parsed maps in widgets or blocs.
- **Repository per feature** exposing domain types, never `Response` or `DioException`. Register with `GetIt` at startup.
- **Typed failures:** map `DioException` and status codes to a sealed `Failure`: `NetworkFailure`, `TimeoutFailure`, `UnauthorizedFailure`, `ValidationFailure(fields)`, `InsufficientBalanceFailure`, `NotFoundFailure`, `ServerFailure`. Every screen renders a message from the failure type, never a raw exception string.
- Status-code mapping must match the backend: 400 validation, 401 auth, 404 not found, 409 insufficient balance, 500 server.
- **Retry only at the user's request** (a retry button), reusing the same idempotency key. No automatic retry interceptor, it risks silent double submission.
- No caching layer, no request cancellation, no batching. Out of scope.

## Validation

Pure Dart functions in `domain`, returning a nullable error string. They are the cheapest tests to write and are directly graded.

- Email format, non-empty password.
- Beneficiary name required; mobile exactly 10 digits; amount parses to a number greater than zero with at most 2 decimals; remarks optional and length-capped.
- The client never pre-rejects a transfer for insufficient balance. That verdict belongs to the backend (409).

## Backend (Node + Express)

- Single process, in-memory store seeded from `seed.json` with at least 10 transactions. Document that a restart resets state.
- Check-and-deduct is one synchronous block with no `await` between reading the balance and writing it, so concurrent transfers cannot overdraft.
- Idempotency store keyed by header value, holding a payload hash plus the stored response. Same key and same payload returns the original response with no second deduction; same key with a different payload returns 409.
- One error middleware; one JSON error shape across every endpoint; no stack traces in responses.

## Testing

Flutter: the four mandatory cases plus `TransferBloc` transitions against a mocked repository (`mocktail`): idle to submitting to success, and idle to submitting to failure for insufficient balance.

Backend: idempotency (same key same payload, same key different payload), parallel transfers never overdrawing, and auth required on every protected route.

## Definition of done, per slice

1. Every acceptance ID in the slice passes by hand.
2. The slice's tests are green.
3. `flutter analyze` clean.
4. Every file explainable without notes.
5. `DECISIONS.md` updated with any choice made and why.
6. AI-generated components noted for the README disclosure.

Do not start the next slice until all six hold. Bonus features wait until every mandatory ID passes.
