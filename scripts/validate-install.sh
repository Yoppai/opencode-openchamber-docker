#!/bin/bash
set -euo pipefail

# Task 1.3: Validate global install of @openchamber/web
# Installs globally, verifies which openchamber + --version,
# saves evidence to evidence/install.log and evidence/binary-check.log

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVIDENCE_DIR="$SCRIPT_DIR/../evidence"
PACKAGE="@openchamber/web@latest"

echo "=== [1.3] Global install validation: $PACKAGE ==="
echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

# --- Step 1: npm install -g ---
echo "[STEP 1] Installing $PACKAGE globally..."
npm install -g "$PACKAGE" 2>&1 | tee "$EVIDENCE_DIR/install.log"
INSTALL_EXIT=${PIPESTATUS[0]}
if [ $INSTALL_EXIT -ne 0 ]; then
    echo ""
    echo "FAIL: npm install -g exited with code $INSTALL_EXIT"
    echo "Check evidence/install.log for details."
    exit 1
fi
echo "PASS: npm install -g completed (exit code 0)"
echo "Install log saved to evidence/install.log"
echo ""

# --- Step 2: Binary check ---
echo "[STEP 2] Verifying binary in PATH..."
{
    echo "=== Binary Check ==="
    echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "Package: $PACKAGE"
    echo ""

    # which openchamber
    BINARY_PATH=$(which openchamber 2>&1)
    WHICH_EXIT=$?
    echo "--- which openchamber ---"
    echo "exit code: $WHICH_EXIT"
    echo "path: $BINARY_PATH"
    echo ""

    # openchamber --version
    echo "--- openchamber --version ---"
    openchamber --version 2>&1 || echo "ERROR: openchamber --version returned non-zero"
    echo ""

    # openchamber --help (informational)
    echo "--- openchamber --help ---"
    openchamber --help 2>&1 || echo "ERROR: openchamber --help returned non-zero"
    echo ""

    # Summary
    echo "--- Summary ---"
    if [ $WHICH_EXIT -eq 0 ]; then
        echo "Binary found in PATH: YES"
        echo "Binary location: $BINARY_PATH"
    else
        echo "Binary found in PATH: NO"
    fi
} > "$EVIDENCE_DIR/binary-check.log"

echo "Binary check saved to evidence/binary-check.log"

# --- Assert ---
if command -v openchamber &>/dev/null; then
    VERSION=$(openchamber --version 2>/dev/null || echo "unknown")
    echo "PASS: openchamber binary located at $(which openchamber)"
    echo "PASS: openchamber --version = $VERSION"
else
    echo "FAIL: openchamber binary not found in PATH after global install"
    echo "Check evidence/binary-check.log and evidence/install.log"
    exit 1
fi
echo ""

echo "=== [1.3] Complete ==="
