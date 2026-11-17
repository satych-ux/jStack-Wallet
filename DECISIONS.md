# Architecture decisions

One entry per decision. This feeds the README's "Architecture decisions" section and doubles as interview prep.

| # | Decision | Why | Trade-off accepted |
|---|---|---|---|
| 1 | Node.js + Express for the mock backend | The assignment names it as preferred; no deviation to justify | Less familiar than Python, but less code to explain |
| 2 | Bloc for state management | Sealed states give exhaustive compile-time checking; `BlocSelector` gives precise rebuild control; `droppable()` solves duplicate submit declaratively | More boilerplate than Riverpod |
| 3 | Backend is the only owner of wallet balance | Explicit business rule in the spec; also the correct real-world design | Extra round trip after a transfer |
| 4 | Idempotency key generated when the confirmation screen opens | Lets a timeout retry reuse the same key, so a retry cannot double-deduct | Key must be cleared when a new transfer starts |
| 5 | No automatic retry interceptor | An auto-retry on a transfer endpoint risks silent double submission; retry is user-initiated and keyed | Slightly worse UX on flaky networks |
| 6 | Search and Credit/Debit filter applied client-side | The spec's list endpoint has no query params; the dataset is small | Would not scale past a few hundred rows; noted as a limitation |
| 7 | In-memory backend store, single process | Spec allows in-memory; keeps the check-and-deduct atomic without a database | State resets on restart; documented |

<!-- Add new rows as you go. Keep the "why" in one sentence you can say out loud. -->
