#!/usr/bin/env bash
# validate-image.sh — build-container-image (ch-02)
# Build local image + validate binaries + user identity + openchamber serve smoke
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
PASS=0
FAIL=0

IMAGE_NAME="opencode-openchamber"
BUILD_LOG="evidence/ch-02/build.log"
VALIDATE_LOG="evidence/ch-02/validate.log"
EVIDENCE_DIR="evidence/ch-02"

mkdir -p "${EVIDENCE_DIR}"

pass() { PASS=$((PASS+1)); echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { FAIL=$((FAIL+1)); echo -e "${RED}[FAIL]${NC} $1"; }
info() { echo -e "${YELLOW}[INFO]${NC} $1"; }

# ── 2.1 Build local image ──────────────────────────────────────────
info "Building image ${IMAGE_NAME} (default versions)..."
if docker build -t "${IMAGE_NAME}" . 2>&1 | tee "${BUILD_LOG}"; then
    pass "docker build exitoso"
else
    fail "docker build falló"
    info "Abortando — build necesario para validaciones posteriores"
    echo "SUMMARY: BUILD FAILED — cannot continue" | tee -a "${VALIDATE_LOG}"
    exit 1
fi

# ── 2.2 Verify 7 binaries return version ────────────────────────────
info "Verificando 7 binarios en PATH..."
BINARIES=(
    "opencode:--version"
    "openchamber:--version"
    "bun:--version"
    "gh:--version"
    "git:--version"
    "ssh:-V"
    "tini:--version"
)

for entry in "${BINARIES[@]}"; do
    bin="${entry%%:*}"
    flag="${entry##*:}"
    if docker run --rm "${IMAGE_NAME}" "${bin}" "${flag}" > /dev/null 2>&1; then
        pass "${bin} ${flag} retorna OK"
    else
        fail "${bin} ${flag} falló"
    fi
done

# ── 2.3 Assert user identity ────────────────────────────────────────
info "Verificando usuario openchamber UID/GID 1000..."
ID_OUTPUT=$(docker run --rm "${IMAGE_NAME}" id openchamber 2>&1)
echo "id openchamber: ${ID_OUTPUT}" | tee -a "${VALIDATE_LOG}"
if echo "${ID_OUTPUT}" | grep -q "uid=1000.*gid=1000"; then
    pass "openchamber UID/GID 1000"
else
    fail "openchamber UID/GID no es 1000"
fi

# ── 2.4 Smoke test: openchamber serve >5s sin error CLI ausente ────
info "Smoke test: openchamber serve --foreground --host 0.0.0.0 --port 3000 (>5s)..."
SERVE_LOG=$(mktemp)
docker run --rm -d --name openchamber-smoke "${IMAGE_NAME}" \
    openchamber serve --foreground --host 0.0.0.0 --port 3000 \
    > "${SERVE_LOG}" 2>&1 || true
sleep 6

# Check container still running after >5s (prevents false-positive on early exit)
RUNNING_AFTER=$(docker inspect -f '{{.State.Running}}' openchamber-smoke 2>/dev/null || echo "false")
CONTAINER_LOG=$(docker logs openchamber-smoke 2>&1 || echo "CONTAINER_EXITED_NO_LOG")
docker kill openchamber-smoke > /dev/null 2>&1 || true
echo "Serve log: ${CONTAINER_LOG}" | tee -a "${VALIDATE_LOG}"
echo "Running after 6s: ${RUNNING_AFTER}" | tee -a "${VALIDATE_LOG}"

SMOKE_FAILED=false
if [ "${RUNNING_AFTER}" != "true" ]; then
    SMOKE_FAILED=true
    fail "openchamber serve: container exited before 6s (State.Running=false)"
fi
if echo "${CONTAINER_LOG}" | grep -qi "Unable to locate the opencode CLI"; then
    SMOKE_FAILED=true
    fail "openchamber serve: detectado error 'Unable to locate the opencode CLI'"
fi
if [ "${SMOKE_FAILED}" = false ]; then
    pass "openchamber serve activo >5s (running=${RUNNING_AFTER})"
fi
rm -f "${SERVE_LOG}"

# ── 2.5 Build with explicit versions ────────────────────────────────
info "Build con versiones explicitas OPENCODE_VERSION=1.0.0 OPENCHAMBER_VERSION=1.9.10..."
EXPLICIT_LOG="${EVIDENCE_DIR}/build-explicit.log"
if docker build \
    --build-arg OPENCODE_VERSION=1.0.0 \
    --build-arg OPENCHAMBER_VERSION=1.9.10 \
    -t "${IMAGE_NAME}:explicit" . 2>&1 | tee "${EXPLICIT_LOG}"; then
    pass "build con versiones explicitas exitoso"
    # Verify versions installed inside
    VERIFY_LOG=$(docker run --rm "${IMAGE_NAME}:explicit" opencode --version 2>&1)
    echo "opencode version: ${VERIFY_LOG}" >> "${VALIDATE_LOG}"
    if echo "${VERIFY_LOG}" | grep -q "1.0.0"; then
        pass "opencode version 1.0.0 confirmada"
    else
        fail "opencode version no es 1.0.0 (got: ${VERIFY_LOG})"
    fi
    CHAMBER_VER=$(docker run --rm "${IMAGE_NAME}:explicit" openchamber --version 2>&1)
    echo "openchamber version: ${CHAMBER_VER}" >> "${VALIDATE_LOG}"
    if echo "${CHAMBER_VER}" | grep -q "1.9.10"; then
        pass "openchamber version 1.9.10 confirmada"
    else
        fail "openchamber version no es 1.9.10 (got: ${CHAMBER_VER})"
    fi
else
    fail "build con versiones explicitas falló"
fi

# ── Summary ─────────────────────────────────────────────────────────
TOTAL=$((PASS+FAIL))
echo "" | tee -a "${VALIDATE_LOG}"
echo "═══════════════════════════════════════" | tee -a "${VALIDATE_LOG}"
echo "  VALIDATION SUMMARY" | tee -a "${VALIDATE_LOG}"
echo "  ${PASS}/${TOTAL} checks passed, ${FAIL} failed" | tee -a "${VALIDATE_LOG}"
echo "═══════════════════════════════════════" | tee -a "${VALIDATE_LOG}"

if [ "${FAIL}" -eq 0 ]; then
    echo -e "${GREEN}ALL CHECKS PASSED${NC}" | tee -a "${VALIDATE_LOG}"
else
    echo -e "${RED}SOME CHECKS FAILED${NC}" | tee -a "${VALIDATE_LOG}"
fi

exit "${FAIL}"
