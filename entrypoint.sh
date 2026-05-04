#!/bin/bash
set -euo pipefail

# ============================================================
# entrypoint.sh — OpenChamber Docker Entrypoint
# Ensures config directory exists, applies defensive SSH permissions,
# resolves password, and execs openchamber (runs in foreground by default).
# ============================================================

# --- Ensure OpenCode config directory exists ---
# OPENCHAMBER_CONFIG_DIR defaults to ~/.config/opencode (OpenCode's config dir).
# OpenCode handles its own config creation on first launch.
CONFIG_DIR="${OPENCHAMBER_CONFIG_DIR:-$HOME/.config/opencode}"

# Ensure config parent directory exists and is writable
mkdir -p "$CONFIG_DIR" 2>/dev/null || true
if [ ! -w "$CONFIG_DIR" ]; then
  echo "[entrypoint] ERROR: $CONFIG_DIR no tiene permisos de escritura" >&2
  echo "[entrypoint] Ejecuta en el host: sudo chown -R 1000:1000 ./data ./workspaces" >&2
  exit 1
fi

# --- Defensive permissions (ch-04) ---
# Ensure SSH directory permissions are correct after volume mount.
# Docker bind mounts may not preserve Unix permissions on all platforms.
if [ -d "$HOME/.ssh" ]; then
  chmod 700 "$HOME/.ssh" || echo "[entrypoint] WARNING: no se pudo aplicar chmod 700 a ~/.ssh — revisa permisos en el host" >&2
  find "$HOME/.ssh" -type f -exec chmod 600 {} \; 2>/dev/null || true
fi

# --- Password resolution ---
# Priority: UI_PASSWORD > OPENCHAMBER_UI_PASSWORD > none (warn on stderr)
UI_PASSWORD="${UI_PASSWORD:-${OPENCHAMBER_UI_PASSWORD:-}}"

# OpenChamber reads OPENCHAMBER_HOST env var (no --host CLI flag needed)
export OPENCHAMBER_HOST="${OPENCHAMBER_HOST:-0.0.0.0}"
PORT="${OPENCHAMBER_PORT:-8080}"

if [ -n "$UI_PASSWORD" ]; then
  exec openchamber --port "$PORT" --ui-password "$UI_PASSWORD"
else
  echo "[entrypoint] WARNING: UI_PASSWORD is not set — OpenChamber will start without password protection" >&2
  exec openchamber --port "$PORT"
fi
