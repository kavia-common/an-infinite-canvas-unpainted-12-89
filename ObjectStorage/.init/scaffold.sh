#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/an-infinite-canvas-unpainted-12-89/ObjectStorage"
mkdir -p "$WS" && cd "$WS"
[ -f package.json ] && exit 0
cat > package.json <<'JSON'
{
  "name": "objectstorage-ui",
  "version": "0.1.0",
  "private": true,
  "engines": { "node": ">=16" },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test --watchAll=false"
  },
  "dependencies": {
    "react": "18.2.0",
    "react-dom": "18.2.0",
    "react-scripts": "5.0.1",
    "dotenv": "16.3.1",
    "json-server": "0.17.3"
  }
}
JSON
# Do NOT generate a fake package-lock.json; deps step will create a lockfile deterministically if needed.
mkdir -p src public && cat > public/index.html <<'HTML'
<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head><body><div id="root"></div></body></html>
HTML
cat > src/index.js <<'JS'
import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
const root = createRoot(document.getElementById('root'));
root.render(<App />);
JS
cat > src/App.js <<'JS'
import React from 'react';
export default function App(){return <div>ObjectStorage UI</div>}
JS
mkdir -p "$WS"/uploads
cat > .gitignore <<'GIT'
node_modules/
build/
.env
GIT
cat > .env.example <<'ENV'
# Example environment variables for local development
REACT_APP_API_URL=http://localhost:3001
ENV
