#!/usr/bin/env bash
set -euo pipefail

flutter pub get
flutter build appbundle --release \
  --dart-define=LOTTERIES_API_URL=https://loteriasrd.workers.dev/results

echo "AAB generado en: build/app/outputs/bundle/release/app-release.aab"
