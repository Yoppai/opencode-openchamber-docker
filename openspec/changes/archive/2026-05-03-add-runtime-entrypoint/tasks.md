# Tasks: add-runtime-entrypoint

## Phase 1: Infrastructure

- [x] 1.1 Agregar `jq` a la lista de paquetes `apt-get install` en `Dockerfile`
- [x] 1.2 Crear `entrypoint.sh` con shebang, `set -euo pipefail`, y funciones stub para seed/merge, password y exec
- [x] 1.3 Actualizar `Dockerfile`: copiar `entrypoint.sh` a `/usr/local/bin/entrypoint.sh` antes de `USER openchamber`, ejecutar `chmod +x`, y redefinir `ENTRYPOINT ["tini", "--", "/usr/local/bin/entrypoint.sh"]` con `CMD []`

## Phase 2: Core Implementation

- [x] 2.1 Implementar seed/merge de configuración en `entrypoint.sh`: crear `~/.config/opencode/opencode.jsonc` con `plugin: ["opencode-synced"]` si no existe; si existe, usar `jq` para agregar `opencode-synced` idempotentmente con backup previo
- [x] 2.2 Implementar password handling en `entrypoint.sh`: mapear `UI_PASSWORD` a flag `--ui-password`; si está vacío, emitir warning a stderr y continuar; si `UI_PASSWORD` está vacío pero `OPENCHAMBER_UI_PASSWORD` tiene valor, usar el fallback
- [x] 2.3 Implementar `exec openchamber serve --foreground --host <OPENCHAMBER_HOST> --port <OPENCHAMBER_PORT>` incluyendo `--ui-password` solo cuando aplique, para que `openchamber` quede como hijo directo de `tini`

## Phase 3: Testing / Validation

- [x] 3.1 Ejecutar `shellcheck` sobre `entrypoint.sh` y corregir cualquier warning (1 info: SC2016 — intencional, echo literal)
- [x] 3.2 Construir imagen Docker localmente y verificar que `jq` está presente en el PATH, `entrypoint.sh` tiene permisos de ejecución, y `ENTRYPOINT` apunta a `tini` → `entrypoint.sh`
- [x] 3.3 Smoke test con `UI_PASSWORD=secret`: arrancar contenedor, inspeccionar proceso con `ps`, y validar que el comando incluye `--ui-password secret` (OpenChamber log "UI password protection enabled" confirma flag; `ps` no disponible en container minimal)
- [x] 3.4 Smoke test sin `UI_PASSWORD`: arrancar contenedor, capturar logs, y validar que aparece warning en stderr y el contenedor continúa iniciando OpenChamber sin flag `--ui-password`
- [x] 3.5 Smoke test con config existente: montar volumen con `opencode.jsonc` que contiene comentarios y campos de usuario, arrancar contenedor dos veces, y validar que `opencode-synced` aparece exactamente una vez y los campos originales se preservan

## Phase 4: Corrections post-verify

- [x] 4.1 CRITICAL: Corregir soporte `opencode.json`: entrypoint ahora busca `opencode.jsonc` primero, luego `opencode.json`, y solo crea `opencode.jsonc` si ninguno existe. Sync-config spec exige detectar ausencia de ambos archivos.
- [x] 4.2 CRITICAL: Corregir preservación JSONC: antes de modificar, usa `grep` para verificar si `opencode-synced` ya está presente. Si ya está → no modifica (preserva comments/estructura). Si debe modificar → usa `jq` con backup (acepta pérdida de comments como tradeoff). Eliminado `sed` que borraba comentarios.
- [x] 4.3 WARNING: Default `OPENCHAMBER_CONFIG_DIR` queda como `$HOME/.config/opencode` (OpenCode config dir), NO `~/.config/openchamber` como dice spec. Spec tiene error: config operada es `opencode.json[c]` de OpenCode, no de OpenChamber. Ruta documentada en comentarios.
