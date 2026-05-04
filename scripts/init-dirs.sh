#!/bin/bash
set -euo pipefail

# ============================================================
# init-dirs.sh — Crea directorios persistentes para OpenChamber
#
# Uso desde project root:
#   ./scripts/init-dirs.sh
#
# Crea los 10 directorios de bind mount definidos en
# docker-compose.yml y aplica permisos estrictos a data/ssh.
# ============================================================

echo "[init-dirs] Creando directorios persistentes..."

# data/openchamber  — config de OpenChamber
mkdir -p data/openchamber
echo "  ✔ data/openchamber"

# data/opencode/*   — config, share, state, cache de OpenCode
mkdir -p data/opencode/config
echo "  ✔ data/opencode/config"
mkdir -p data/opencode/share
echo "  ✔ data/opencode/share"
mkdir -p data/opencode/state
echo "  ✔ data/opencode/state"
mkdir -p data/opencode/cache
echo "  ✔ data/opencode/cache"

# data/agents       — agentes locales
mkdir -p data/agents
echo "  ✔ data/agents"

# data/gh           — config de GitHub CLI
mkdir -p data/gh
echo "  ✔ data/gh"

# data/ssh          — claves SSH (requiere permisos 700)
mkdir -p data/ssh
echo "  ✔ data/ssh"

# data/opencode-multi-auth  — auth multi-cuenta
mkdir -p data/opencode-multi-auth
echo "  ✔ data/opencode-multi-auth"

# workspaces        — directorio de trabajo
mkdir -p workspaces
echo "  ✔ workspaces"

# --- Permisos SSH ---
chmod 700 data/ssh
echo "  ✔ data/ssh — permisos 700"

# Aplica 600 a archivos de clave existentes dentro de data/ssh
if [ -d data/ssh ] && [ -n "$(find data/ssh -mindepth 1 -type f -print -quit 2>/dev/null)" ]; then
  chmod 600 data/ssh/*
  echo "  ✔ data/ssh/* — permisos 600 en claves existentes"
fi

echo ""
echo "[init-dirs] ✓ Completado. Los 10 directorios están listos."
echo "[init-dirs] Siguiente paso: docker compose up -d"
