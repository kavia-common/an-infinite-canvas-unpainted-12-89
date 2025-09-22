#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/an-infinite-canvas-unpainted-12-89/ObjectStorage"
cd "$WS"
# Prefer project/react-scripts lint if available
if node -e 'try{const p=require("./package.json"); if((p.dependencies&&p.dependencies["react-scripts"])||(p.devDependencies&&p.devDependencies["react-scripts"])) process.exit(0); process.exit(1);}catch(e){process.exit(1)}' >/dev/null 2>&1; then
  # use react-scripts lint if available
  if command -v npx >/dev/null 2>&1; then
    npx react-scripts lint src --quiet || { echo "react-scripts lint failed" >&2; exit 12; }
  fi
else
  # fallback to npx eslint scoped to src
  if command -v npx >/dev/null 2>&1; then
    npx eslint src --ext .js,.jsx,.ts,.tsx || { echo "ESLint failed" >&2; exit 13; }
  else
    echo "ERROR: npx not found for lint" >&2; exit 14
  fi
fi
# Run tests: adapt to runner
# Use timeout (GNU coreutils timeout) to avoid long hangs; 300s limit
if node -e 'try{const p=require("./package.json"); if((p.dependencies&&p.dependencies["react-scripts"])||(p.devDependencies&&p.devDependencies["react-scripts"])) process.exit(0); process.exit(1);}catch(e){process.exit(1)}' >/dev/null 2>&1; then
  timeout 300 npm test -- --ci --runInBand --watchAll=false || { echo "Tests failed" >&2; exit 15; }
else
  # use npx jest with CI flags
  timeout 300 npx jest --runInBand --ci || { echo "Jest tests failed" >&2; exit 16; }
fi
