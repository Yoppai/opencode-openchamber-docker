#!/bin/bash
set -euo pipefail

# Task 3.1 + 3.2: Multi-architecture prebuild validation
# Inspects install logs for "prebuild" vs "node-gyp" vs "error"
# across AMD64 and ARM64, then generates evidence/arm-risk-matrix.md

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVIDENCE_DIR="$SCRIPT_DIR/../evidence"
NATIVE_ARCH=$(uname -m)

echo "=== [3.1] ARM/AMD64 prebuild validation ==="
echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Native architecture: $NATIVE_ARCH"
echo ""

ARM_LOG=""
AMD_LOG=""

# Helper: scan install log for native dep status
scan_install_log() {
    local LOG_FILE=$1
    local ARCH=$2
    local KEYWORDS

    if [ ! -f "$LOG_FILE" ]; then
        echo "$ARCH: No install log found at $LOG_FILE"
        return 1
    fi

    echo "Scanning $LOG_FILE for $ARCH native dependency markers..."
    echo ""
    echo "--- $ARCH: install log analysis ---"
    echo "File: $LOG_FILE"

    # Count occurrences
    PREBUILD_COUNT=$(grep -ci "prebuild" "$LOG_FILE" 2>/dev/null || echo 0)
    GYP_COUNT=$(grep -ci "node-gyp\|node_gyp\|gyp " "$LOG_FILE" 2>/dev/null || echo 0)
    ERROR_COUNT=$(grep -ci "error\|ERR!" "$LOG_FILE" 2>/dev/null || echo 0)
    BUILD_FROM_SOURCE=$(grep -ci "build from source\|rebuild\|compiling" "$LOG_FILE" 2>/dev/null || echo 0)
    BETTER_SQLITE3=$(grep -ci "better-sqlite3" "$LOG_FILE" 2>/dev/null || echo 0)
    NODE_PTY=$(grep -ci "node-pty" "$LOG_FILE" 2>/dev/null || echo 0)
    BUN_PTY=$(grep -ci "bun-pty" "$LOG_FILE" 2>/dev/null || echo 0)

    echo "Prebuild downloads:          $PREBUILD_COUNT"
    echo "node-gyp invocations:        $GYP_COUNT"
    echo "Errors:                      $ERROR_COUNT"
    echo "Build-from-source events:    $BUILD_FROM_SOURCE"
    echo "better-sqlite3 mentions:     $BETTER_SQLITE3"
    echo "node-pty mentions:           $NODE_PTY"
    echo "bun-pty mentions:            $BUN_PTY"
    echo ""

    # Extract relevant lines for detail
    echo "--- Relevant lines (prebuild/gyp/error) ---"
    grep -in "prebuild\|node-gyp\|node_gyp\|ERR!\|error.*install\|build from source" "$LOG_FILE" 2>/dev/null | head -30 || echo "(none)"
    echo ""
}

# --- AMD64 scan ---
echo "=============================================="
echo "AMD64 prebuild analysis"
echo "=============================================="
if [ -f "$EVIDENCE_DIR/install.log" ]; then
    AMD_LOG="$EVIDENCE_DIR/install.log"
    scan_install_log "$AMD_LOG" "linux/amd64" | tee /dev/null
    # Capture output
    {
        echo "=== linux/amd64: Install Log Analysis ==="
        scan_install_log "$AMD_LOG" "linux/amd64"
    } > "$EVIDENCE_DIR/arm-install-amd64.log"
else
    echo "WARN: evidence/install.log not found (AMD64 install not run)"
    echo "Run scripts/validate-install.sh first in an AMD64 container."
    {
        echo "=== linux/amd64 ==="
        echo "Status: NOT TESTED"
        echo "Reason: evidence/install.log not found"
        echo "Action: Run validate-install.sh in node:22-bookworm-slim on AMD64 host"
    } > "$EVIDENCE_DIR/arm-install-amd64.log"
fi

# --- ARM64 scan ---
echo ""
echo "=============================================="
echo "ARM64 prebuild analysis"
echo "=============================================="
if [ "$NATIVE_ARCH" = "aarch64" ] || [ "$NATIVE_ARCH" = "arm64" ]; then
    echo "Running on native ARM64 — can validate directly"
    if [ -f "$EVIDENCE_DIR/install.log" ]; then
        ARM_LOG="$EVIDENCE_DIR/install.log"
        scan_install_log "$ARM_LOG" "linux/arm64"
        {
            echo "=== linux/arm64: Install Log Analysis ==="
            scan_install_log "$ARM_LOG" "linux/arm64"
        } > "$EVIDENCE_DIR/arm-install-arm64.log"
    fi
else
    echo "Native architecture is $NATIVE_ARCH (not ARM64)"

    # If ARM64 install log already exists with real data, don't overwrite
    if [ -s "$EVIDENCE_DIR/arm-install-arm64.log" ] && ! grep -q "NOT TESTED" "$EVIDENCE_DIR/arm-install-arm64.log" 2>/dev/null; then
        echo "ARM64 install log exists with real data — preserving."
        ARM64_HAS_DATA=1
    else
        ARM64_HAS_DATA=0
        echo ""
        echo "To validate ARM64, run in QEMU Buildx or native ARM64:"
        echo ""
        echo "  docker run --platform linux/arm64 --rm \\"
        echo "    -v \"$(pwd):/workspace\" \\"
        echo "    node:22-bookworm-slim \\"
        echo "    bash /workspace/scripts/validate-install.sh"
        echo ""
        echo "Then copy evidence/install.log as evidence/arm-install-arm64.log."

        {
            echo "=== linux/arm64 ==="
            echo "Status: NOT TESTED (requires QEMU or native ARM64)"
            echo "Native arch: $NATIVE_ARCH"
            echo ""
            echo "To run on ARM64 via Docker Buildx:"
            echo "  docker run --platform linux/arm64 --rm \\"
            echo "    -v \"$(pwd):/workspace\" \\"
            echo "    node:22-bookworm-slim \\"
            echo "    bash /workspace/scripts/validate-install.sh"
            echo ""
            echo "Then copy install.log as evidence/arm-install-arm64.log and re-run this script."
        } > "$EVIDENCE_DIR/arm-install-arm64.log"
    fi
fi

echo ""
echo "=== [3.1] Complete ==="

# ============================================================
# Task 3.2: Generate ARM risk matrix
# ============================================================
echo ""
echo "=== [3.2] Generating ARM risk matrix ==="

# Determine status for each dep based on log analysis
detect_dep_status() {
    local LOG_FILE=$1
    local DEP=$2

    if [ ! -f "$LOG_FILE" ]; then
        echo "No disponible"
        return
    fi

    if grep -qi "prebuild.*$DEP\|$DEP.*prebuild" "$LOG_FILE" 2>/dev/null; then
        echo "Sí (prebuild)"
        return
    fi
    if grep -qi "$DEP" "$LOG_FILE" 2>/dev/null; then
        if grep -qi "node-gyp\|gyp " "$LOG_FILE" 2>/dev/null; then
            echo "No — requiere compilación"
        else
            echo "Presente (no se detecta prebuild ni gyp)"
        fi
    else
        echo "No detectado"
    fi
}

# detect_dep_status searches the RAW install log (install.log) for dependency markers,
# NOT the analysis summary log (arm-install-amd64.log), because the summary log
# only contains grep counts, not the actual npm install output.
AMD_LOG_FILE="$EVIDENCE_DIR/install.log"

AMD_STATUS=$(detect_dep_status "$AMD_LOG_FILE" "better-sqlite3")
AMD_STATUS_NPTY=$(detect_dep_status "$AMD_LOG_FILE" "node-pty")
AMD_STATUS_BUN=$(detect_dep_status "$AMD_LOG_FILE" "bun-pty")

# ARM_LOG_FILE: MUST be platform-specific, never fall back to AMD64 log
# When running on native ARM64, ARM_LOG is set above from install.log
# When not on ARM64, there is no raw ARM64 install log, so use analysis log
if [ -n "$ARM_LOG" ]; then
    ARM_LOG_FILE="$ARM_LOG"
else
    ARM_LOG_FILE="$EVIDENCE_DIR/arm-install-arm64.log"
fi

ARM_STATUS=$(detect_dep_status "$ARM_LOG_FILE" "better-sqlite3")
ARM_STATUS_NPTY=$(detect_dep_status "$ARM_LOG_FILE" "node-pty")
ARM_STATUS_BUN=$(detect_dep_status "$ARM_LOG_FILE" "bun-pty")

cat > "$EVIDENCE_DIR/arm-risk-matrix.md" << MATRIX_EOF
# ARM64 Risk Matrix

Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Package: @openchamber/web@latest
Native architecture: $NATIVE_ARCH

## Matrix

| Plataforma | Dependencia | Prebuild disponible | Compilación requerida | Resultado |
|---|---|---|---|---|
| linux/amd64 | better-sqlite3 | $AMD_STATUS | — | — |
| linux/amd64 | node-pty | $AMD_STATUS_NPTY | — | — |
| linux/amd64 | bun-pty | $AMD_STATUS_BUN | — | — |
| linux/arm64 | better-sqlite3 | $ARM_STATUS | — | — |
| linux/arm64 | node-pty | $ARM_STATUS_NPTY | — | — |
| linux/arm64 | bun-pty | $ARM_STATUS_BUN | — | — |

## Notes

- **Prebuild descargada**: La dependencia se instaló desde un binario precompilado sin toolchain de compilación.
- **Compilación desde fuente**: npm ejecutó \`node-gyp\` o \`build from source\`, lo que requiere \`build-essential\`, \`python3\`, \`make\`, \`gcc\`.
- **No detectado**: La dependencia no aparece en el log de instalación, posiblemente sea opcional o no se instaló.
- **Mitigación ARM64**: Si alguna dependencia nativa requiere compilación en ARM64, instalar \`build-essential\` + \`python3\` en el Dockerfile de producción (ch-02).
- **Validación QEMU**: Si no se probó ARM64 nativo, los resultados pueden diferir bajo emulación QEMU (más lento, mismo resultado de prebuild).
MATRIX_EOF

echo "PASS: evidence/arm-risk-matrix.md generated"
echo ""

echo "=== [3.2] Complete ==="
