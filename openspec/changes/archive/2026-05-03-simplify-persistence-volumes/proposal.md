# Proposal: simplify-persistence-volumes

## Intent
Reducir complejidad de volúmenes persistencia: 10 bind mounts → 2. Montar todo `/home/openchamber` como unidad (config, cache, state, agents, plugins, auth) + `workspaces` separado para código fuente.

## Scope
- Modificar `docker-compose.yml`: 10 volumes → 2
- Modificar `scripts/init-dirs.sh`: 10 directorios → 2
- Actualizar spec `persistence` con nueva matriz simplificada
- Ajustar `entrypoint.sh`: chmod SSH defensivo no silencioso

## Non-goals
- No modificar lógica de sync (`opencode-synced`)
- No modificar Dockerfile
- No cambiar comportamiento runtime más allá de permisos SSH
- No modificar spec `runtime-config` (entrypoint ya cubre la lógica)

## Capabilities
1. Mount `data/home` persiste todo `/home/openchamber`: config, cache, state, agents, gh, SSH, multi-auth, npm, bun, plugins
2. Mount `workspaces` separado para código fuente (gestión independiente)
3. SSH permisos manejados por `entrypoint.sh` con warning visible
4. `init-dirs.sh` simplificado a `data/home` + `workspaces`

## Approach
Matriz de volúmenes de 10 a 2 usando mount padre. `openchamber-synced` cubre sync cross-machine; volúmenes cubren sobrevivencia tras rebuild. Sin conflicto entre ambos.

## Dependencies
- ch-04 `add-compose-persistence` (archivado)

## Risks

| Riesgo | Mitigación |
|---|---|
| Home completo persiste más datos de lo necesario | Beneficio: plugins arbitrarios tienen persistencia sin configuración adicional |
| Host user ≠ UID 1000 en Linux | `init-dirs.sh` aplica `chmod 755` defensivo + nota de `chown 1000:1000` |
| SSH permisos heredados del host | `entrypoint.sh` fuerza `chmod 700` con warning si falla |
| Cache + config en mismo mount | Aceptable para MVP; usuario puede borrar `data/home/.cache` manualmente |

## Success Criteria
- [ ] `docker-compose.yml` tiene 2 volumes: `data/home` y `workspaces`
- [ ] `init-dirs.sh` crea `data/home/` y `workspaces/`
- [ ] Contenedor escribe en `~/.config/opencode/opencode.jsonc` sin permission denied
- [ ] Config/state/cache/agents/auth sobreviven `docker compose down && docker compose up -d`
- [ ] `gh auth` persiste tras recrear contenedor
