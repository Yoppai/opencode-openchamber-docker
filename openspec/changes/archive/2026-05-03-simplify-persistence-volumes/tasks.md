# Tasks: simplify-persistence-volumes

## Phase 1: Compose + Init

- [x] 1.1 Modificar `docker-compose.yml`: reemplazar bloque `volumes:` (10 mounts) por 2 mounts (`data/home`, `workspaces`). Actualizar comentarios.
- [x] 1.2 Verificar sintaxis con `docker compose config`

## Phase 2: Init Script

- [x] 2.1 Modificar `scripts/init-dirs.sh`: 10 `mkdir -p` → 2 (`data/home`, `workspaces`). Eliminar bloque SSH específico. Agregar `chmod 777` defensivo.
- [x] 2.2 Verificar sintaxis con `bash -n scripts/init-dirs.sh`

## Phase 3: Entrypoint

- [x] 3.1 Modificar `entrypoint.sh`: bloque SSH de silencioso a no silencioso (warning si chmod falla)
- [x] 3.2 Verificar sintaxis con `bash -n entrypoint.sh`

## Phase 4: Spec Sync

- [x] 4.1 Actualizar `openspec/specs/persistence/spec.md` con nueva matriz simplificada (2 mounts, 5 requirements)

## Phase 5: Verification

- [x] 5.1 Ejecutar `scripts/init-dirs.sh` y validar `data/home/` + `workspaces/` existen
- [x] 5.2 Validar persistencia: `docker compose down && docker compose up -d`, verificar config sobrevive
- [x] 5.3 Validar `docker compose config` muestra 2 volumes (✅ verificado en verify)
