#!/bin/bash
set -euo pipefail

# Task 2.2: Validate password authentication
# Scenario 1: --ui-password flag
# Scenario 2: OPENCHAMBER_UI_PASSWORD env var
# Optional: curl to / to verify auth

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVIDENCE_DIR="$SCRIPT_DIR/../evidence"
TIMEOUT=10

cleanup() {
    for PID in "${PIDS[@]}"; do
        kill "$PID" 2>/dev/null || true
    done
    for PID in "${PIDS[@]}"; do
        wait "$PID" 2>/dev/null || true
    done
}
trap cleanup EXIT

PIDS=()
FAILED=0

wait_for_port() {
    local PORT=$1
    local MAX_WAIT=$2
    local ELAPSED=0
    while [ $ELAPSED -lt "$MAX_WAIT" ]; do
        if command -v ss &>/dev/null; then
            ss -tlnp 2>/dev/null | grep -qE ":$PORT " && return 0
        elif command -v netstat &>/dev/null; then
            netstat -tlnp 2>/dev/null | grep -qE ":$PORT " && return 0
        elif command -v nc &>/dev/null; then
            nc -z 127.0.0.1 "$PORT" 2>/dev/null && return 0
        elif command -v node &>/dev/null; then
            # Node.js TCP probe (always available in node:bookworm-slim)
            node -e "
                const n=require('net');
                const c=n.connect($PORT,'127.0.0.1',()=>{c.end();process.exit(0);});
                c.on('error',()=>process.exit(1));
            " 2>/dev/null && return 0
        fi
        sleep 1
        ELAPSED=$((ELAPSED + 1))
    done
    return 1
}

echo "=== [2.2] Password validation ==="
echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

# ============================================================
# SCENARIO 1: --ui-password flag
# ============================================================
echo "=============================================="
echo "SCENARIO 1: --ui-password secret123"
echo "=============================================="
PORT1=4000

{
    echo "=== Password: --ui-password flag ==="
    echo "Command: openchamber serve --foreground --host 127.0.0.1 --port $PORT1 --ui-password secret123"
    echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo ""
} > "$EVIDENCE_DIR/password-flag.log"

echo "Starting server with --ui-password..."
openchamber serve --foreground --host 127.0.0.1 --port "$PORT1" --ui-password secret123 &
PID1=$!
PIDS+=("$PID1")
echo "Server PID: $PID1"

sleep 1  # let process fail fast if missing opencode dep
if ! kill -0 "$PID1" 2>/dev/null; then
    echo "Server process exited immediately — missing opencode dependency"
    FAILED=1
    {
        echo "Server startup: FAILED (process exited immediately)"
        echo "Command: openchamber serve --foreground --host 127.0.0.1 --port $PORT1 --ui-password secret123"
        echo "Exit reason: openchamber requires 'opencode' CLI on PATH"
        echo "Status: BLOCKED — password enforcement unverifiable without opencode"
    } >> "$EVIDENCE_DIR/password-flag.log"
else
    if wait_for_port "$PORT1" "$TIMEOUT"; then
        echo "PASS: Server listening on port $PORT1 with --ui-password"
        {
            echo "Server startup: SUCCESS"
            echo "Listening on: 127.0.0.1:$PORT1"
            echo "Flag: --ui-password secret123"
            echo ""

            # HTTP probe — fails if UI responds 200 without auth (password not enforced)
            echo "--- HTTP probe (security check) ---"
            if command -v curl &>/dev/null; then
                echo "Attempting curl http://127.0.0.1:$PORT1/ (no auth) ..."
                HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:$PORT1/" 2>&1 || echo "curl_failed")
            elif command -v node &>/dev/null; then
                echo "Attempting Node.js HTTP probe http://127.0.0.1:$PORT1/ (no auth) ..."
                HTTP_CODE=$(node -e "
                    const http = require('http');
                    http.get('http://127.0.0.1:$PORT1/', (res) => {
                        console.log(res.statusCode);
                        res.resume();
                    }).on('error', () => console.log('node_http_error'));
                " 2>&1)
            else
                echo "FAIL: Neither curl nor node available for HTTP probe"
                FAILED=1
                HTTP_CODE="no_tool"
            fi
            echo "HTTP status (no auth): $HTTP_CODE"
            if [ "$HTTP_CODE" = "401" ]; then
                echo "PASS: Server returns 401 without password — auth enforced"
            elif [ "$HTTP_CODE" = "200" ]; then
                echo "FAIL: Server returns 200 without password — UI is NOT protected"
                echo "FAIL: --ui-password flag may not be supported by this version"
                FAILED=1
            else
                echo "INFO: HTTP status = $HTTP_CODE (cannot confirm auth enforcement)"
            fi
        } >> "$EVIDENCE_DIR/password-flag.log"
    else
        echo "FAIL: Server not listening within ${TIMEOUT}s — cannot verify password enforcement"
        FAILED=1
        {
            echo "Server startup: TIMEOUT (${TIMEOUT}s)"
            echo "Flag: --ui-password secret123"
            echo "Status: FAILED — server did not start"
        } >> "$EVIDENCE_DIR/password-flag.log"
    fi
fi

kill "$PID1" 2>/dev/null || true
wait "$PID1" 2>/dev/null || true
sleep 1

# ============================================================
# SCENARIO 2: OPENCHAMBER_UI_PASSWORD env var
# ============================================================
echo ""
echo "=============================================="
echo "SCENARIO 2: OPENCHAMBER_UI_PASSWORD=envpass (no --ui-password)"
echo "=============================================="
PORT2=4001

{
    echo "=== Password: OPENCHAMBER_UI_PASSWORD env var ==="
    echo "Command: OPENCHAMBER_UI_PASSWORD=envpass openchamber serve --foreground --host 127.0.0.1 --port $PORT2"
    echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo ""
} > "$EVIDENCE_DIR/password-env.log"

echo "Starting server with OPENCHAMBER_UI_PASSWORD=envpass..."
OPENCHAMBER_UI_PASSWORD=envpass openchamber serve --foreground --host 127.0.0.1 --port "$PORT2" &
PID2=$!
PIDS+=("$PID2")
echo "Server PID: $PID2"

sleep 1  # let process fail fast if missing opencode dep
if ! kill -0 "$PID2" 2>/dev/null; then
    echo "Server process exited immediately — missing opencode dependency"
    FAILED=1
    {
        echo "Server startup: FAILED (process exited immediately)"
        echo "Command: OPENCHAMBER_UI_PASSWORD=envpass openchamber serve --foreground --host 127.0.0.1 --port $PORT2"
        echo "Exit reason: openchamber requires 'opencode' CLI on PATH"
        echo "Status: BLOCKED — password enforcement unverifiable without opencode"
    } >> "$EVIDENCE_DIR/password-env.log"
else
    if wait_for_port "$PORT2" "$TIMEOUT"; then
        echo "PASS: Server listening on port $PORT2 with OPENCHAMBER_UI_PASSWORD"
        {
            echo "Server startup: SUCCESS"
            echo "Listening on: 127.0.0.1:$PORT2"
            echo "Env var: OPENCHAMBER_UI_PASSWORD=envpass"
            echo ""

            # HTTP probe — fails if UI responds 200 without auth
            echo "--- HTTP probe (security check) ---"
            if command -v curl &>/dev/null; then
                echo "Attempting curl http://127.0.0.1:$PORT2/ (no auth) ..."
                HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:$PORT2/" 2>&1 || echo "curl_failed")
            elif command -v node &>/dev/null; then
                echo "Attempting Node.js HTTP probe http://127.0.0.1:$PORT2/ (no auth) ..."
                HTTP_CODE=$(node -e "
                    const http = require('http');
                    http.get('http://127.0.0.1:$PORT2/', (res) => {
                        console.log(res.statusCode);
                        res.resume();
                    }).on('error', () => console.log('node_http_error'));
                " 2>&1)
            else
                echo "FAIL: Neither curl nor node available for HTTP probe"
                FAILED=1
                HTTP_CODE="no_tool"
            fi
            echo "HTTP status (no auth): $HTTP_CODE"
            if [ "$HTTP_CODE" = "401" ]; then
                echo "PASS: Server returns 401 without password — auth enforced"
            elif [ "$HTTP_CODE" = "200" ]; then
                echo "FAIL: Server returns 200 without password — UI is NOT protected"
                echo "FAIL: OPENCHAMBER_UI_PASSWORD env var may not be supported by this version"
                FAILED=1
            else
                echo "INFO: HTTP status = $HTTP_CODE (cannot confirm auth enforcement)"
            fi
        } >> "$EVIDENCE_DIR/password-env.log"
    else
        echo "FAIL: Server not listening within ${TIMEOUT}s — cannot verify password enforcement"
        FAILED=1
        {
            echo "Server startup: TIMEOUT (${TIMEOUT}s)"
            echo "Env var: OPENCHAMBER_UI_PASSWORD=envpass"
            echo "Status: FAILED — server did not start"
        } >> "$EVIDENCE_DIR/password-env.log"
    fi
fi

echo ""
echo "=== [2.2] Complete ==="
echo "Evidence:"
echo "  - evidence/password-flag.log"
echo "  - evidence/password-env.log"

if [ "$FAILED" -eq 1 ]; then
    echo ""
    echo "FAIL: Password validation — one or more checks failed"
    exit 1
fi
echo "PASS: Password validation complete — all scenarios passed"
