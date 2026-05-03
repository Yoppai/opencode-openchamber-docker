# Proposal: build-container-image

## Intent

Crear imagen de producción con OpenCode + OpenChamber sobre `node:22-bookworm-slim`. Resolver bloqueador crítico de ch-01: `openchamber serve` requiere `opencode` en PATH.

## Scope

### In Scope
- Dockerfile producción multi-stage (builder/runtime si es seguro copiar artefactos).
- Instalar `opencode-ai` antes que `@openchamber/web`.
- Instalar `bash`, `ca-certificates`, `git`, `gh`, `openssh-client`, `tini` y Bun.
- Usuario no-root `openchamber` UID/GID 1000.
- Validación local build/run y smoke test `openchamber serve` con `opencode` presente.
- Verificar binarios disponibles en PATH.

### Out of Scope
- Entrypoint password mapping / seed merge `opencode-synced` (ch-03).
- Compose y persistencia (ch-04).
- Publicación GHCR multi-arch (ch-06).
- Docs productivos (ch-07).

## Capabilities

### New Capabilities
- `container-image`: Dockerfile y contenido de imagen.
- `runtime-config`: usuario runtime, PATH y env esperados.

### Modified Capabilities
- None.

## Approach

Dockerfile multi-stage desde `node:22-bookworm-slim`. Instalar deps OS y Bun. `npm install -g opencode-ai@${OPENCODE_VERSION:-latest}` primero, luego `@openchamber/web@${OPENCHAMBER_VERSION:-latest}`. Limpiar caches apt/npm en misma capa. Crear usuario `openchamber`. Smoke test: `openchamber serve --foreground --host 0.0.0.0 --port 3000` debe arrancar sin error “Unable to locate the opencode CLI”.

## Affected Areas

| Area | Impact | Description |
|---|---|---|
| `Dockerfile` | New | Definición imagen producción. |
| `scripts/validate-image.sh` | New | Script validación build/run local. |
| `openspec/specs/container-image/spec.md` | New | Spec contenido imagen. |
| `openspec/specs/runtime-config/spec.md` | New | Spec comportamiento runtime. |

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| OpenChamber no encuentra opencode post-install | Low | Smoke test obligatorio; setear `OPENCODE_BINARY` si aplica. |
| Deps nativas requieren build tools en ARM64 | Low | Prebuilds confirmados en ch-01; fallback `build-essential` + `python3` comentado. |
| Bloat por installs globales npm | Med | Multi-stage; prune caches; copiar solo artefactos runtime. |

## Rollback Plan

Eliminar `Dockerfile`, script de validación y specs generados. Volver a estado pre-ch-02 sin imagen.

## Dependencies

- Evidencia ch-01: instalación npm funciona y bloqueador `opencode` documentado.
- Base `node:22-bookworm-slim` disponible.

## Success Criteria

- [ ] `docker build -t opencode-openchamber .` exitoso local.
- [ ] Contenedor muestra usuario `openchamber` UID/GID 1000.
- [ ] `opencode --version`, `openchamber --version`, `bun --version`, `gh --version`, `git --version`, `ssh -V`, `tini --version` retornan sin error.
- [ ] `openchamber serve --foreground --host 0.0.0.0 --port 3000` permanece activo >5 s sin error “Unable to locate the opencode CLI”.
