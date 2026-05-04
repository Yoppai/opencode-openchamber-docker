#!/bin/bash
set -euo pipefail

# ============================================================
# entrypoint.sh — OpenChamber Docker Entrypoint (ch-03)
# Seeds/merges opencode config (json/jsonc), resolves password,
# and execs openchamber serve --foreground under tini.
# ============================================================

# --- Seed/merge opencode config ---
# OPENCHAMBER_CONFIG_DIR defaults to ~/.config/opencode (OpenCode's config dir).
# The variable is OpenChamber-named for env consistency, but the config managed
# is OpenCode's opencode.json[c]. Aligned with runtime-config spec.
CONFIG_DIR="${OPENCHAMBER_CONFIG_DIR:-$HOME/.config/opencode}"

# Ensure config parent directory exists and is writable
mkdir -p "$CONFIG_DIR" 2>/dev/null || true
if [ ! -w "$CONFIG_DIR" ]; then
  echo "[entrypoint] ERROR: $CONFIG_DIR no tiene permisos de escritura" >&2
  echo "[entrypoint] Ejecuta en el host: sudo chown -R 1000:1000 ./data ./workspaces" >&2
  exit 1
fi

# Priority: opencode.jsonc > opencode.json > create opencode.jsonc
if [ -f "$CONFIG_DIR/opencode.jsonc" ]; then
  CONFIG="$CONFIG_DIR/opencode.jsonc"
elif [ -f "$CONFIG_DIR/opencode.json" ]; then
  CONFIG="$CONFIG_DIR/opencode.json"
else
  CONFIG="$CONFIG_DIR/opencode.jsonc"
fi

if [ ! -f "$CONFIG" ]; then
  # No config exists — seed with base config
  mkdir -p "$(dirname "$CONFIG")"
  echo '{"$schema":"https://opencode.ai/config.json","plugin":["opencode-synced"]}' > "$CONFIG"
else
  # Config exists — check if opencode-synced already present via grep.
  # grep is used instead of jq to avoid stripping JSONC comments on read-only checks.
  if grep -q '"opencode-synced"' "$CONFIG"; then
    # Already present — no modification needed (preserves comments, structure)
    :
  else
    # Need to add opencode-synced — backup, strip // comments, merge with jq.
    # jq cannot parse JSONC comments; sed strips them before merge (accepted tradeoff:
    # comments are lost on modification, but merge succeeds instead of failing).
    cp "$CONFIG" "$CONFIG.bak.$$"
    sed '/^[[:space:]]*\/\//d' "$CONFIG.bak.$$" > "$CONFIG.bak.jq.$$"
    if jq 'if has("plugin") then .plugin+=["opencode-synced"] else .+{"plugin":["opencode-synced"]} end' "$CONFIG.bak.jq.$$" > "$CONFIG" 2>/dev/null; then
      rm -f "$CONFIG.bak.$$" "$CONFIG.bak.jq.$$"
    else
      mv "$CONFIG.bak.$$" "$CONFIG"
      rm -f "$CONFIG.bak.jq.$$"
      echo "[entrypoint] ERROR: jq merge failed — original config restored" >&2
      exit 1
    fi
  fi
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

HOST="${OPENCHAMBER_HOST:-0.0.0.0}"
PORT="${OPENCHAMBER_PORT:-8080}"

if [ -n "$UI_PASSWORD" ]; then
  exec openchamber serve --foreground --host "$HOST" --port "$PORT" --ui-password "$UI_PASSWORD"
else
  echo "[entrypoint] WARNING: UI_PASSWORD is not set — OpenChamber will start without password protection" >&2
  exec openchamber serve --foreground --host "$HOST" --port "$PORT"
fi
