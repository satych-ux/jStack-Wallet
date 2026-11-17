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
| Node.js | 20 or newer |
| Android | TODO: emulator API level / device used |

## Backend setup

```bash
cd backend
npm install
npm start          # listens on http://localhost:3000
```

Data is held in memory and seeded from `seed.json` on boot. **State resets on every restart**, which is intentional for a mock.

Health check:

```bash
curl http://localhost:3000/api/v1/health
```

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

TODO: link the Bruno collection in `api/bruno/` and `api/openapi.yaml`.

## Known limitations

TODO. Candidates to document:
- Backend state is in-memory and resets on restart.
- Transaction search and filtering are applied client-side over the fetched list.
- Add Money is a UI stub, as the assignment specifies.
- Single backend process; concurrency safety relies on that.

## AI-assisted development disclosure

TODO: list the components that were substantially AI-generated, and confirm that all submitted code has been reviewed and is explainable.

Tooling used: TODO.
