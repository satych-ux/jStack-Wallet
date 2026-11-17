#!/usr/bin/env bash
# One-time dependency setup. Uses `flutter pub add` so pub resolves versions
# compatible with your installed SDK rather than pinning guessed ones.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> Flutter dependencies"
cd app
flutter pub add \
  flutter_bloc \
  bloc_concurrency \
  equatable \
  dio \
  go_router \
  flutter_secure_storage \
  get_it \
  uuid \
  intl \
  json_annotation
flutter pub add --dev \
  mocktail \
  bloc_test \
  build_runner \
  json_serializable
flutter pub get
cd ..

echo "==> Backend dependencies"
cd backend
npm install
cd ..

echo "==> Done. Start the backend with: cd backend && npm start"
