#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/an-infinite-canvas-unpainted-12-89/ObjectStorage"
cd "$WORKSPACE"
export CI=true
export BROWSER=none
# ensure package.json has test script
node -e "let fs=require('fs');let p=require('./package.json');p.scripts=p.scripts||{};p.scripts.test=p.scripts.test||'react-scripts test --passWithNoTests --watchAll=false';fs.writeFileSync('package.json',JSON.stringify(p,null,2))"
# detect package manager
PKG_MGR=npm
[ -f yarn.lock ] && PKG_MGR=yarn
# Create test file compatible with react-scripts (uses import syntax)
mkdir -p src/__tests__
cat > src/__tests__/smoke.test.js <<'EOF'
import React from 'react';
import { render } from '@testing-library/react';
import App from '../App';
test('smoke: render root component if present', ()=>{
  if(!App) { expect(true).toBeTruthy(); return; }
  const {container} = render(React.createElement(App));
  expect(container).toBeTruthy();
});
EOF
# Ensure react-scripts and testing libs are present; install if missing
if ! command -v react-scripts >/dev/null 2>&1 || ! node -e "try{require('react-scripts');require('@testing-library/react');}catch(e){process.exit(1)}"; then
  if [ "$PKG_MGR" = "yarn" ]; then
    yarn add --dev react-scripts @testing-library/react @testing-library/jest-dom --silent
    yarn install --silent
  else
    npm i --save-dev react-scripts @testing-library/react @testing-library/jest-dom --silent
    npm i --silent
  fi
fi
# Run tests via chosen package manager and capture logs
LOG="${WORKSPACE}/jest_log_$(date -u +%s).log"
if [ "$PKG_MGR" = "yarn" ]; then
  if ! yarn test --silent --runInBand >"$LOG" 2>&1; then echo "tests failed - see: $LOG" >&2; exit 3; fi
else
  if ! npm test --silent -- --runInBand >"$LOG" 2>&1; then echo "tests failed - see: $LOG" >&2; exit 3; fi
fi
exit 0
