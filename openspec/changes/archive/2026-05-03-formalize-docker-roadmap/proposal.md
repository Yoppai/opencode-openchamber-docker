# Proposal: Formalizar Roadmap Docker en OpenSpec

## Intent

PRD y roadmap existen pero no son trazables via `openspec status`. Falta mapping de criterios de aceptacion a artifacts formales y dominios spec candidatos para cambios posteriores. Este change cierra ese gap.

## Scope

### In Scope
- Crear change formal `formalize-docker-roadmap`.
- Mapear criterios de aceptacion PRD §502-513 a spec/design/task.
- Definir dominios spec candidatos para ch-01..ch-07.
- Actualizar ROADMAP con estado, dependencias y gaps.

### Non-goals
- Implementar Dockerfile, entrypoint, Compose, CI o docs producto.
- Validar runtime `@openchamber/web` o construir imagen.

## Capabilities

### New Capabilities
- `spec-domain-registry`: definicion de dominios spec candidatos (`container-image`, `runtime-config`, `persistence`, `sync-config`, `ghcr-publishing`, `vps-quickstart`) y mapping PRD -> artifacts.

### Modified Capabilities
- None.

## Approach

Leer PRD §502-513 y clasificar cada criterio:
- Spec: comportamiento observable (ej. imagen multi-arch publicada).
- Design: decision tecnica (ej. usar Buildx + QEMU).
- Task: paso implementable (ej. crear workflow GH Actions).

Registrar dominios spec en tabla con change relacionado y estado registrado. Actualizar ROADMAP marcando ch-00 en progreso.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `openspec/changes/formalize-docker-roadmap/` | New | Estructura change formal |
| `openspec/ROADMAP.md` | Modified | Estado ch-00, mapping, gaps |
| `openspec/specs/` | New | Directorios dominios candidatos con README placeholder |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Mapeo incompleto deja gaps | Med | Checklist contra §502-513 |
| Over-scope implementa Docker | Med | Out-of-scope explicito |
| Nombres dominios inconsistentes | Low | Kebab-case, alinear con ROADMAP |

## Rollback Plan

Eliminar `openspec/changes/formalize-docker-roadmap/` y revertir ediciones en `openspec/ROADMAP.md`.

## Dependencies

- `openspec/PRD.md` completo.
- `openspec/config.yaml` con schema `spec-driven`.

## Success Criteria

- [x] Proposal creado con intent, scope, capabilities.
- [x] Cada criterio §502-513 mapeado a spec/design/task.
- [x] Dominios spec candidatos definidos con descripcion.
- [x] ROADMAP refleja ch-00 en progreso.
