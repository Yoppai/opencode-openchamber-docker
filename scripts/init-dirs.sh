#!/bin/bash
set -euo pipefail

# ============================================================
# init-dirs.sh — Crea directorios persistentes para OpenChamber
#
# Uso desde project root:
#   ./scripts/init-dirs.sh
#
# Crea los 2 directorios de bind mount definidos en
# docker-compose.yml y aplica permisos defensivos.
# ============================================================

echo "[init-dirs] Creando directorios persistentes..."

mkdir -p data/home
echo "  ✔ data/home"

mkdir -p workspaces
echo "  ✔ workspaces"

# Permisos defensivos: asegura que container UID 1000 pueda escribir
chmod -R 777 data/ workspaces/ 2>/dev/null || true

echo ""
echo "[init-dirs] ✓ Completado. 2 directorios listos."
echo "[init-dirs] AVISO Linux: si el contenedor falla con 'Permission denied', ejecuta:"
echo "[init-dirs]   sudo chown -R 1000:1000 data/ workspaces/"
echo "[init-dirs] Siguiente paso: docker compose up -d"
