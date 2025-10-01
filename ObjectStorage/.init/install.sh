#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/an-infinite-canvas-unpainted-12-89/ObjectStorage"
cd "$WS"
[ -f package.json ] || { echo 'package.json missing; run scaffold first' >&2; exit 2; }
USE_YARN=0
if command -v yarn >/dev/null 2>&1; then USE_YARN=1; fi
# If no lockfile, create one deterministically using npm (package-lock-only) unless override
if [ $USE_YARN -eq 1 ]; then
  if [ -f yarn.lock ]; then
    yarn install --silent --frozen-lockfile || { echo 'yarn --frozen-lockfile failed' >&2; exit 3; }
  else
    if [ "${ALLOW_UNPINNED_INSTALL:-false}" != "true" ]; then
      # generate yarn.lock by running yarn install --silent but do not modify package.json
      yarn install --silent || { echo 'yarn install to generate yarn.lock failed' >&2; exit 4; }
      yarn install --silent --frozen-lockfile || { echo 'yarn --frozen-lockfile failed post-lock generation' >&2; exit 5; }
    else
      yarn install --silent || { echo 'yarn install failed' >&2; exit 6; }
    fi
  fi
else
  if [ -f package-lock.json ]; then
    npm ci --no-audit --no-fund --silent || { echo 'npm ci failed' >&2; exit 7; }
  else
    if [ "${ALLOW_UNPINNED_INSTALL:-false}" != "true" ]; then
      npm install --package-lock-only --no-audit --no-fund --silent || { echo 'npm --package-lock-only failed' >&2; exit 8; }
      npm ci --no-audit --no-fund --silent || { echo 'npm ci failed after generating package-lock' >&2; exit 9; }
    else
      npm install --no-audit --no-fund --silent || { echo 'npm install failed' >&2; exit 10; }
    fi
  fi
fi
# verify local react-scripts binary
if [ ! -x ./node_modules/.bin/react-scripts ]; then
  echo 'react-scripts not installed in node_modules; install may have failed' >&2; exit 11
fi
# print minimal versions for debugging
echo "node:$(node -v 2>/dev/null || echo unknown) npm:$(npm -v 2>/dev/null || echo unknown) yarn:$(command -v yarn >/dev/null 2>&1 && yarn -v || echo none)"
# try local react-scripts version
if [ -x ./node_modules/.bin/react-scripts ]; then
  ./node_modules/.bin/react-scripts --version 2>/dev/null || true
fi
