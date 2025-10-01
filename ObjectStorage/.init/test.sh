#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/an-infinite-canvas-unpainted-12-89/ObjectStorage"
cd "$WS"
[ -f package.json ] || { echo 'package.json missing; run scaffold first' >&2; exit 2; }
mkdir -p src/__tests__
cat > src/__tests__/smoke.test.js <<'JS'
test('smoke: simple assertion', () => { expect(1).toBe(1); });
JS
# ensure test script exists but prefer direct invocation of local binary
export CI=true
export BROWSER=none
if [ -x ./node_modules/.bin/react-scripts ]; then
  ./node_modules/.bin/react-scripts test --watchAll=false --runInBand || { echo 'tests failed' >&2; exit 3; }
else
  # fallback to npm test
  npm test --silent -- --watchAll=false --runInBand || { echo 'tests failed' >&2; exit 4; }
fi
# print brief test summary (count lines with PASS/FAIL)
grep -E "PASS|FAIL" -m 20 -n -H --null src || true
