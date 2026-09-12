#!/usr/bin/env bash
set -euo pipefail

API_URL="${LOTTERIES_API_URL:-https://api.sorteosdominicanos.workers.dev/results}"
KEY_PROPERTIES="android/key.properties"
AAB_PATH="build/app/outputs/bundle/release/sorteosdominicanos.aab"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not available in PATH."
  exit 1
fi

if ! command -v java >/dev/null 2>&1; then
  echo "Java/JDK is not available in PATH."
  exit 1
fi

echo "Flutter version:"
flutter --version

echo "Java version:"
java -version

echo "Validating backend before build..."
API_BASE="${API_URL%/results}" ./test_backend.sh

echo "Checking Android release signing files..."
if [ ! -f "$KEY_PROPERTIES" ]; then
  echo "Missing ${KEY_PROPERTIES}. Copy android/key.properties.example to ${KEY_PROPERTIES} and fill the Play upload key values."
  exit 1
fi

for key in storePassword keyPassword keyAlias storeFile; do
  if ! grep -q "^${key}=" "$KEY_PROPERTIES"; then
    echo "Missing ${key} in ${KEY_PROPERTIES}."
    exit 1
  fi
done

STORE_FILE="$(awk -F= '/^storeFile=/ {print $2}' "$KEY_PROPERTIES" | tail -1)"
if [ -z "$STORE_FILE" ]; then
  echo "The configured keystore file is empty in ${KEY_PROPERTIES}."
  exit 1
fi

if [[ "$STORE_FILE" = /* ]]; then
  RESOLVED_STORE_FILE="$STORE_FILE"
else
  RESOLVED_STORE_FILE="android/$STORE_FILE"
fi

if [ ! -f "$RESOLVED_STORE_FILE" ]; then
  echo "The configured keystore file does not exist: ${RESOLVED_STORE_FILE}"
  exit 1
fi

echo "Cleaning and fetching dependencies..."
flutter clean
flutter pub get

echo "Running static analysis..."
flutter analyze --no-fatal-infos --no-fatal-warnings

if [ -d "test" ] && find test -name '*_test.dart' -print -quit | grep -q .; then
  echo "Running Flutter tests..."
  flutter test
else
  echo "No Flutter test files found; skipping flutter test."
fi

echo "Building debug APK..."
flutter build apk --debug --dart-define=LOTTERIES_API_URL="$API_URL"

echo "Building signed release App Bundle..."
flutter build appbundle --release --dart-define=LOTTERIES_API_URL="$API_URL"

if [ ! -f "$AAB_PATH" ]; then
  echo "AAB was not generated at ${AAB_PATH}."
  exit 1
fi

echo "AAB ready: ${AAB_PATH}"
if command -v shasum >/dev/null 2>&1; then
  shasum -a 256 "$AAB_PATH"
elif command -v sha256sum >/dev/null 2>&1; then
  sha256sum "$AAB_PATH"
fi

echo "Release validation passed."
