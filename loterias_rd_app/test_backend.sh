#!/usr/bin/env bash
set -euo pipefail

API_BASE="${API_BASE:-https://api.sorteosdominicanos.workers.dev}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

check_endpoint() {
  local path="$1"
  local expected_status="$2"
  local body="$TMP_DIR/body.json"
  local headers="$TMP_DIR/headers.txt"

  echo "Checking ${API_BASE}${path}"
  local status
  status="$(curl -sS -L -D "$headers" -o "$body" -w "%{http_code}" "${API_BASE}${path}")"
  local content_type
  content_type="$(awk 'BEGIN{IGNORECASE=1} /^content-type:/ {print $0}' "$headers" | tail -1)"

  echo "  status: ${status}"
  echo "  ${content_type:-content-type: missing}"

  if [ "$status" != "$expected_status" ]; then
    echo "Unexpected HTTP status for ${path}. Expected ${expected_status}, got ${status}."
    head -c 1000 "$body" || true
    echo
    exit 1
  fi

  node -e "JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8')); console.log('  json: valid');" "$body"
}

check_endpoint "/health" "200"
check_endpoint "/results" "200"

node - "$TMP_DIR/body.json" <<'NODE'
const fs = require('fs');
const payload = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
if (!Array.isArray(payload.results)) {
  throw new Error('The /results response does not contain a results array.');
}
if (payload.results.length === 0) {
  throw new Error('The /results response returned zero results.');
}
const first = payload.results[0];
const required = ['lotteryName', 'drawName', 'drawDate', 'numbers'];
const missing = required.filter((key) => first[key] == null);
if (missing.length) {
  throw new Error(`First result is missing required fields: ${missing.join(', ')}`);
}
console.log(`  results: ${payload.results.length}`);
console.log(`  source: ${payload.source || 'not reported'}`);
console.log(`  first draw: ${first.lotteryName} - ${first.drawName} - ${first.drawDate}`);
NODE

echo "Backend validation passed."
