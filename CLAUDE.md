# jWallet Lite

jStack Round-1 Flutter assignment. Flutter app in `app/`, mock Express backend in `backend/`.

## Working agreement

- All work follows `.claude/skills/jwallet-lite-build/SKILL.md` and the acceptance IDs in `SPEC.md`. Read both before writing code.
- Build in **vertical slices, in the order listed in SPEC.md section 12**. Do not start a slice until the previous one meets the definition of done (SPEC.md section 11).
- Work **one slice per session**. Do not touch files outside the current slice without being asked.
- After each slice, run a critic pass with fresh context: review the diff against the slice's acceptance IDs, list violations and missing edge cases, fix nothing until told.
- Record every non-obvious choice in `DECISIONS.md` as you make it.
- Log AI-generated components as you go; the README must disclose them.

## The six rules that fail the grading

1. The backend owns the balance. The app never computes it.
2. No static JSON in the app standing in for the backend.
3. Every transfer carries an `Idempotency-Key`, reused on retry of the same attempt.
4. Seven distinct screens. Confirmation and Result do not merge.
5. The four mandatory tests exist and pass.
6. Every file must be explainable by the author. Simpler beats clever.

## Commands

```bash
# backend
cd backend && npm install && npm start      # http://localhost:3000
cd backend && npm test

# app (Android emulator reaches the host at 10.0.2.2)
cd app && flutter pub get
cd app && flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
cd app && flutter test
cd app && flutter analyze
```
