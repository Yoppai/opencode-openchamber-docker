# Tasks: Formalizar Roadmap Docker en OpenSpec

## Phase 1: Formalización base

- [x] 1.1 Revisar `openspec/changes/formalize-docker-roadmap/proposal.md` y alinear scope/non-goals con `openspec/PRD.md` §502-513 y `openspec/ROADMAP.md` Fase 0.
- [x] 1.2 Verificar `openspec/changes/formalize-docker-roadmap/specs/spec-domain-registry/spec.md` cubra mapeo 504-513, dominios candidatos y scope boundary; corregir escenarios si falta uno.
- [x] 1.3 Verificar `openspec/changes/formalize-docker-roadmap/design.md` incluya método PRD→artifact, control de riesgos y gate anti-over-scope.

## Phase 2: Registry y roadmap

- [x] 2.1 Crear/normalizar `openspec/specs/<domain>/README.md` placeholders para `container-image`, `runtime-config`, `persistence`, `sync-config`, `ghcr-publishing` y `vps-quickstart` si el design los exige.
- [x] 2.2 Actualizar `openspec/ROADMAP.md`: ch-00 como `in-progress`/formalized, links a `formalize-docker-roadmap`, dependencias y estado de specs; no marcar archivado.
- [x] 2.3 Registrar en `openspec/ROADMAP.md` el grafo ch-01..ch-07 y gaps críticos sin introducir Docker, Compose ni CI.

## Phase 3: Trazabilidad PRD

- [x] 3.1 Mapear PRD §502-513 en `design.md` a una tabla única spec/design/task con change destino.
- [x] 3.2 Asegurar que cada criterio tenga destino único y que §504-513 queden reflejados en el registry/domain mapping.
- [x] 3.3 Confirmar que `spec-domain-registry/spec.md` documente explícitamente que ch-00 no crea `Dockerfile`, `entrypoint.sh`, `docker-compose.yml` ni workflows.

## Phase 4: Verificación

- [x] 4.1 Validar que no exista `openspec/changes/ch-00/`; sólo `openspec/changes/formalize-docker-roadmap/`.
- [x] 4.2 Verificar que no se creó implementación productiva: `Dockerfile`, `docker-compose.yml`, `.github/workflows/` o cambios en código app.
- [x] 4.3 Revisar que la aceptación PRD §502-513 quedó mapeada y que el change quedó listo para sdd-apply.
- [x] 4.4 Registrar `openspec validate formalize-docker-roadmap --strict` como gate previo a verify/archive.
