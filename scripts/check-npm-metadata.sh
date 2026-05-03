#!/bin/bash
set -euo pipefail

# Task 1.2: npm metadata validation
# Runs npm view --json on @openchamber/web@latest, validates bin.openchamber,
# saves result to evidence/npm-metadata.log

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVIDENCE_DIR="$SCRIPT_DIR/../evidence"
PACKAGE="@openchamber/web@latest"

echo "=== [1.2] npm metadata check: $PACKAGE ==="
echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

# --- Step 1: Fetch full metadata via npm view ---
echo "[STEP 1] Fetching npm metadata..."
METADATA=$(npm view "$PACKAGE" --json 2>&1) || {
    echo "FAIL: npm view $PACKAGE failed"
    echo "Command: npm view $PACKAGE --json" > "$EVIDENCE_DIR/npm-metadata.log"
    echo "Exit code: $?" >> "$EVIDENCE_DIR/npm-metadata.log"
    exit 1
}
echo "$METADATA" > "$EVIDENCE_DIR/npm-metadata.log"
echo "PASS: npm metadata saved to evidence/npm-metadata.log ($(wc -c < "$EVIDENCE_DIR/npm-metadata.log") bytes)"
echo ""

# --- Step 2: Validate bin.openchamber ---
echo "[STEP 2] Validating bin.openchamber..."
BIN_PATH=$(node -e "
const d = JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'));
const bin = d.bin;
if (typeof bin === 'object' && bin.openchamber) {
    console.log(bin.openchamber);
} else if (typeof bin === 'string') {
    console.log(bin);
} else {
    process.exit(1);
}
" "$EVIDENCE_DIR/npm-metadata.log" 2>/dev/null) || {
    echo "FAIL: bin.openchamber is missing or empty"
    exit 1
}
echo "PASS: bin.openchamber = '$BIN_PATH'"
echo ""

# --- Step 3: Extract key metadata fields ---
echo "[STEP 3] Key metadata summary:"
{
    echo "name:         $(node -e "console.log(JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')).name||'N/A')" "$EVIDENCE_DIR/npm-metadata.log")"
    echo "version:      $(node -e "console.log(JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')).version||'N/A')" "$EVIDENCE_DIR/npm-metadata.log")"
    echo "bin:          $(node -e "const d=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'));console.log(JSON.stringify(d.bin||{}))" "$EVIDENCE_DIR/npm-metadata.log")"
    echo "dependencies: $(node -e "const d=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'));console.log(Object.keys(d.dependencies||{}).join(', ')||'(none)')" "$EVIDENCE_DIR/npm-metadata.log")"
}
echo ""

# --- Step 4: Check dist-tags for latest ---
echo "[STEP 4] Checking dist-tags..."
DIST_TAGS=$(npm view "$PACKAGE" dist-tags --json 2>/dev/null || echo '{}')
echo "dist-tags: $DIST_TAGS"
echo ""

# --- Step 5: npm pack --dry-run to verify tarball contents ---
echo "[STEP 5] Running npm pack --dry-run..."
npm pack "$PACKAGE" --dry-run > "$EVIDENCE_DIR/npm-pack.log" 2>&1 || {
    echo "WARN: npm pack --dry-run returned non-zero exit"
}
if grep -q "bin/cli.js" "$EVIDENCE_DIR/npm-pack.log" 2>/dev/null; then
    echo "PASS: bin/cli.js confirmed in tarball contents"
else
    echo "WARN: bin/cli.js not found in npm pack --dry-run output"
fi
echo "npm pack --dry-run output saved to evidence/npm-pack.log"
echo ""

echo "=== [1.2] Complete ==="
echo "Result: PASS (bin.openchamber = '$BIN_PATH')"
