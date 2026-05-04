# Proposal: add-compose-persistence (ch-04)

## Intent

La imagen y entrypoint ya existen (ch-02, ch-03), pero falta orquestación para persistir datos. Sin volúmenes host, recrear contenedor pierde config, state, cache, auth GitHub, SSH, agents y workspaces. Este change entrega `docker-compose.yml`, `.env.example` e `init-dirs.sh` para hacer el despliegue reproducible y persistente.

## Scope

### In Scope
- `docker-compose.yml` con servicio `openchamber` y 10 volúmenes host mapeados.
- `.env.example` con 18 variables runtime documentadas (excluye build args).
- `scripts/init-dirs.sh` para crear directorios persistentes con permisos correctos (SSH `700`/`600`).
- Ajuste defensivo en `entrypoint.sh` para reafirmar permisos `~/.ssh`.

### Out of Scope
- Sync real vía `opencode-synced` (solo infraestructura de volúmenes; ch-05).
- CI/CD multi-arch (ch-06).
- Documentación completa de troubleshooting (ch-07).
- Reverse proxy / TLS.
- Validación de fortaleza de password.

## Capabilities

### New Capabilities
- `persistence`: matriz de 10 volúmenes host→contenedor, permisos SSH, supervivencia a recreación.
- `vps-quickstart`: `docker compose up -d openchamber`, `.env.example`, `init-dirs.sh`.

### Modified Capabilities
- `runtime-config`: variables runtime ahora se inyectan vía compose `environment` / `.env`; el entrypoint debe seguir funcionando con defaults cuando no están definidas.

## Approach

- `docker-compose.yml`: servicio `openchamber`, image local o GHCR, puerto expuesto, 10 binds tipo volume host según matriz PRD §325-338.
- `.env.example`: todas las variables runtime del PRD §424-480; `OPENCHAMBER_VERSION` y `OPENCODE_VERSION` se omiten (son build args).
- `scripts/init-dirs.sh`: `mkdir -p` para `data/{openchamber,opencode/{config,share,state,cache},agents,gh,ssh,opencode-multi-auth}` y `workspaces`; `chmod 700 data/ssh`; `set -euo pipefail`.
- `entrypoint.sh`: si `~/.ssh` existe, `chmod 700` defensivo al arrancar.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `docker-compose.yml` | New | Orquestación compose con volúmenes persistentes. |
| `.env.example` | New | Variables runtime documentadas para usuario. |
| `scripts/init-dirs.sh` | New | Bootstrap inicial de directorios host. |
| `entrypoint.sh` | Modified | Defensive `chmod 700` en `~/.ssh` si existe. |
| `openspec/specs/persistence/` | New | Delta spec: comportamiento de volúmenes. |
| `openspec/specs/vps-quickstart/` | New | Delta spec: quickstart compose e init. |
| `openspec/specs/runtime-config/` | Modified | Delta spec: variables vía compose environment. |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|-------------|
| Permisos SSH incorrectos | Med | `init-dirs.sh` setea `700`; entrypoint reafirma. |
| Volumen host sobreescribe config seedeada | Low | Entrypoint corre después de mount; merge preserva campos. |
| `.env` con secrets commiteado | Low | `.gitignore` ya excluye `.env`; `.env.example` sin valores sensibles. |

## Rollback Plan

- Eliminar `docker-compose.yml`, `.env.example`, `scripts/init-dirs.sh`.
- Revertir cambios a `entrypoint.sh`.
- `docker compose down` y reconstruir imagen con tag anterior si aplica.

## Dependencies

- `ch-03` `add-runtime-entrypoint` (✅ archived)

## Success Criteria

- [ ] `docker compose up -d openchamber` levanta servicio sin errores.
- [ ] `docker compose down && docker compose up -d` preserva config, state, cache, gh auth, SSH, agents y workspaces.
- [ ] `.env.example` documenta todas las variables runtime esperadas.
- [ ] `scripts/init-dirs.sh` crea todos los directorios con permisos correctos.
- [ ] Directorio `data/ssh` tiene `700` y archivos de clave `600` después de init.
