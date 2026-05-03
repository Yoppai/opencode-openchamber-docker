# Proposal: Spike — Validar Runtime npm de OpenChamber

## Intent

Validar que `@openchamber/web` publica binario funcional, que los flags CLI esperados (`--foreground`, `--host`, `--port`, `--ui-password`) operan correctamente, y que ARM64 no bloquea por dependencias nativas. Evitar invertir en Dockerfile/CI sobre supuestos falsos.

## Why now

ch-01 es prerequisito técnico para ch-02..ch-07. ROADMAP gap #3 señala que sin esta validación se puede construir infraestructura completa alrededor de un binario o flags inexistentes. Bloquea toda Fase 1.

## Scope

### In Scope
- Script de validación: `npm install -g @openchamber/web` + invocación binario + flags.
- Matriz ARM64 vs AMD64 para `better-sqlite3`, `node-pty`, `bun-pty`.
- Documento de decisiones: Go/No-go para ch-02, flags confirmados, vars entorno necesarias, mitigaciones ARM.
- Nota técnica sobre mapeo `UI_PASSWORD` → `--ui-password`.

### Non-goals
- Dockerfile de producción, imagen local, entrypoint, CI, Compose, docs usuario.
- Seed/merge de `opencode-synced`.
- Publicación GHCR.

## Capabilities

### New Capabilities
- None. Spike no introduce comportamiento productivo; produce artefactos de validación.

### Modified Capabilities
- None.

## Approach

Instalar `@openchamber/web@latest` en entorno limpio (node:22-bookworm-slim). Verificar:
1. Binario `openchamber` existe en PATH.
2. `serve --foreground --host --port` arranca.
3. `--ui-password` o `OPENCHAMBER_UI_PASSWORD` funcionan.
4. Deps nativas resuelven o documentan fallback compilación ARM.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `openspec/changes/spike-openchamber-npm-runtime/` | New | Artefactos spike |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|-------------|
| `--ui-password` no soportado upstream | Low | Usar `OPENCHAMBER_UI_PASSWORD`; documentar en decisiones |
| ARM64 requiere compilación nativa lenta | Med | Preinstalar `build-essential` + `python3` en ch-02 |
| `node-pty` sin prebuild ARM64 | Med | Validar durante spike; fallback a PTY degradado si aplica |

## Rollback Plan

Eliminar `openspec/changes/spike-openchamber-npm-runtime/` y descartar artefactos de validación. No hay cambios en código productivo.

## Dependencies

- `ch-00` archivado (dominios spec registrados).
- `openspec/PRD.md` §101-133, §482-496.
- Acceso a registry npm para `@openchamber/web`.

## Acceptance Gates

- [ ] `npm install -g @openchamber/web@latest` expone binario `openchamber` en PATH.
- [ ] `openchamber serve --foreground --host 0.0.0.0 --port 3000` arranca sin error.
- [ ] Password UI funciona vía `--ui-password` o `OPENCHAMBER_UI_PASSWORD`.
- [ ] ARM64: se documenta estado de prebuilds para `better-sqlite3`, `node-pty`, `bun-pty`.
- [ ] Documento de decisiones declara Go para ch-02 con mitigaciones, o No-go con blockers.
