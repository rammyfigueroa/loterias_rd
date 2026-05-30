#!/usr/bin/env bash
set -euo pipefail

flutter build web \
  --dart-define=LOTTERIES_API_URL=https://loteriasrd.workers.dev/results
