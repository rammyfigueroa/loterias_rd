#!/usr/bin/env bash
set -euo pipefail

flutter run -d chrome \
  --dart-define=LOTTERIES_API_URL=https://loteriasrd.workers.dev/results
