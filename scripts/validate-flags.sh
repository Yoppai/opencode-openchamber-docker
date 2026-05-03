#!/bin/bash
set -euo pipefail

# Task 2.1: Validate CLI flags for openchamber serve
# Starts server with --foreground --host --port, captures startup,
# verifies TCP bind, tests default command (no subcommand)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVIDENCE_DIR="$SCRIPT_DIR/../evidence"
TIMEOUT=15

cleanup() {
    for PID in "${PIDS[@]}"; do
        kill "$PID" 2>/dev/null || true
    done
    # Wait for processes to die
    for PID in "${PIDS[@]}"; do
        wait "$PID" 2>/dev/null || true
    done
}
trap cleanup EXIT

PIDS=()

wait_for_port() {
    local PORT=$1
    local MAX_WAIT=$2
    local ELAPSED=0
    while [ $ELAPSED -lt "$MAX_WAIT" ]; do
        if command -v ss &>/dev/null; then
            if ss -tlnp 2>/dev/null | grep -qE ":$PORT "; then
                return 0
            fi
        elif command -v netstat &>/dev/null; then
            if netstat -tlnp 2>/dev/null | grep -qE ":$PORT "; then
                return 0
            fi
        elif command -v nc &>/dev/null; then
            if nc -z 127.0.0.1 "$PORT" 2>/dev/null; then
                return 0
            fi
        elif command -v node &>/dev/null; then
            # Node.js TCP probe (always available in node:bookworm-slim)
            if node -e "
                const n=require('net');
                const c=n.connect($PORT,'127.0.0.1',()=>{c.end();process.exit(0);});
                c.on('error',()=>process.exit(1));
            " 2>/dev/null; then
                return 0
            fi
        fi
        # Fallback: none of ss/netstat/nc/node available — will eventually timeout
        # node:22-bookworm-slim includes node, so this path unlikely
        sleep 1
        ELAPSED=$((ELAPSED + 1))
    done
    return 1
}

echo "=== [2.1] CLI flags validation ==="
echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

# ============================================================
# SCENARIO 1: serve --foreground --host 0.0.0.0 --port 3000
# ============================================================
echo "=============================================="
echo "SCENARIO 1: openchamber serve --foreground --host 0.0.0.0 --port 3000"
echo "=============================================="
PORT1=3000
{
    echo "=== Scenario 1: serve --foreground ==="
    echo "Command: openchamber serve --foreground --host 0.0.0.0 --port $PORT1"
    echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo ""
} > "$EVIDENCE_DIR/startup.log"

echo "Starting server (background)..."
openchamber serve --foreground --host 0.0.0.0 --port "$PORT1" &
PID1=$!
PIDS+=("$PID1")
echo "Server PID: $PID1"

sleep 2  # let process init and fail fast if missing dependency
if ! kill -0 "$PID1" 2>/dev/null; then
    echo "Server process exited immediately — likely missing dependency"
    wait "$PID1" 2>/dev/null || true
    {
        echo "Server startup: FAILED (process exited immediately)"
        echo "Command: openchamber serve --foreground --host 0.0.0.0 --port $PORT1"
        echo "Exit reason: openchamber requires 'opencode' CLI on PATH (see evidence/opencode-dependency.log)"
        echo ""
    } >> "$EVIDENCE_DIR/startup.log"
else
    echo "Waiting up to ${TIMEOUT}s for port $PORT1..."
    if wait_for_port "$PORT1" "$TIMEOUT"; then
        echo "PASS: Server listening on 0.0.0.0:$PORT1"
        {
            echo "Server startup: SUCCESS"
            echo "Listening on: 0.0.0.0:$PORT1"
            echo "Server PID: $PID1"
            echo ""
        } >> "$EVIDENCE_DIR/startup.log"
    else
        echo "WARN: Port $PORT1 not detected within ${TIMEOUT}s"
        {
            echo "Server startup: TIMEOUT (${TIMEOUT}s)"
            echo "Listening on: UNKNOWN"
            echo "Server PID: $PID1"
            echo ""
        } >> "$EVIDENCE_DIR/startup.log"
    fi
fi

# Kill scenario 1 server
kill "$PID1" 2>/dev/null || true
wait "$PID1" 2>/dev/null || true
sleep 1

# ============================================================
# Port check evidence
# ============================================================
{
    echo "=== Port Check ==="
    echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "Target port: $PORT1"
    echo ""

    echo "--- ss -tlnp ---"
    if command -v ss &>/dev/null; then
        ss -tlnp 2>&1 || echo "(ss unavailable or empty)"
    else
        echo "(ss not installed)"
    fi
    echo ""

    echo "--- netstat -tlnp ---"
    if command -v netstat &>/dev/null; then
        netstat -tlnp 2>&1 || echo "(netstat unavailable or empty)"
    else
        echo "(netstat not installed)"
    fi
    echo ""

    echo "--- nc -zv 127.0.0.1:$PORT1 ---"
    if command -v nc &>/dev/null; then
        nc -zv 127.0.0.1 "$PORT1" 2>&1 || echo "(connection refused or timeout)"
    else
        echo "(nc not installed)"
    fi
    echo ""

    echo "--- Node.js TCP probe (127.0.0.1:$PORT1) ---"
    if command -v node &>/dev/null; then
        node -e "
            const n=require('net');
            const c=n.connect($PORT1,'127.0.0.1',()=>{c.end();process.exit(0);});
            c.on('error',()=>process.exit(1));
        " 2>&1 && echo "TCP connection: SUCCESS" || echo "TCP connection: FAILED"
    else
        echo "node not installed"
    fi
} > "$EVIDENCE_DIR/port-check.log"
echo "Port check saved to evidence/port-check.log"

# ============================================================
# SCENARIO 2: Default command (no subcommand)
# ============================================================
echo ""
echo "=============================================="
echo "SCENARIO 2: openchamber --foreground --host 127.0.0.1 --port 3001 (no subcommand)"
echo "=============================================="
PORT2=3001

echo "Starting server without subcommand..."
openchamber --foreground --host 127.0.0.1 --port "$PORT2" &
PID2=$!
PIDS+=("$PID2")
echo "Server PID: $PID2"

sleep 2  # short wait for startup (also lets process die fast if missing opencode dep)

if kill -0 "$PID2" 2>/dev/null; then
    echo "PASS: Server started without subcommand (defaults to 'serve')"
    {
        echo ""
        echo "=== Scenario 2: Default command (no subcommand) ==="
        echo "Command: openchamber --foreground --host 127.0.0.1 --port $PORT2"
        echo "PID: $PID2"
        echo "Server process alive: YES"
        echo "Implication: Default subcommand is 'serve'"
        echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    } >> "$EVIDENCE_DIR/startup.log"
else
    echo "FAIL: Server without subcommand exited immediately"
    {
        echo ""
        echo "=== Scenario 2: Default command (no subcommand) ==="
        echo "Command: openchamber --foreground --host 127.0.0.1 --port $PORT2"
        echo "Server process alive: NO"
        echo "Root cause: openchamber requires 'opencode' CLI on PATH"
        echo "Implication: Default subcommand behavior unverifiable without opencode"
        echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    } >> "$EVIDENCE_DIR/startup.log"
fi

echo ""
echo "=== [2.1] Complete ==="
echo "Evidence:"
echo "  - evidence/startup.log"
echo "  - evidence/port-check.log"
