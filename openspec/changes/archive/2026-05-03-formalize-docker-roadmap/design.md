# Design: Formalizar Roadmap Docker en OpenSpec

## Technical Approach

Convertir PRD \u00a7502-513 en artifacts OpenSpec trazables sin implementar producto. Establecer estructura de dominios spec y mapping PRD \u2192 spec/design/task para cambios ch-01..ch-07.

## Architecture Decisions

| Decision | Options | Tradeoffs | Choice |
|---|---|---|---|
| Artifact model ch-00 | (a) Proposal + design; (b) + specs placeholders; (c) + tasks completos | (a) No deja estructura; (b) Permite validar dominios sin over-scope; (c) Riesgo de implementar antes de specs | (b): proposal + design + specs candidatos vacíos |
| PRD mapping method | Tabla estática vs script extracción | Script requiere mantenimiento; tabla es suficiente para 10 criterios de aceptación | Tabla estática en design.md con referencia PRD \u2192 change |
| Spec domain registry | Directorio `openspec/specs/<domain>/` vs lista en ROADMAP | Directorio permite evolución independiente; lista centralizada rompe ownership por change | Directorio `openspec/specs/<domain>/` con `README.md` de ownership |
| Acceptance gate | Checklist manual vs `openspec verify` automático | No hay CLI verify aún; manual es realista | Checklist en tasks.md + design.md |

## Data Flow

```
PRD.md \u00a7502-513
    │
    ▼
[Classifier] ──\u2192 spec (comportamiento observable)
    │
    ├──\u2192 design (decisión técnica)
    │
    └──\u2192 task (paso implementable)
            │
            ▼
    openspec/changes/ch-01..ch-07/
            │
            ▼
    openspec/specs/<domain>/
```

## File Changes

| File | Action | Description |
|---|---|---|
| `openspec/changes/formalize-docker-roadmap/design.md` | Create | Decisiones y mapping PRD \u2192 artifacts |
| `openspec/changes/formalize-docker-roadmap/tasks.md` | Create | Checklist ch-00 con gates |
| `openspec/specs/container-image/README.md` | Create | Placeholder ownership ch-02, ch-06 |
| `openspec/specs/runtime-config/README.md` | Create | Placeholder ownership ch-02, ch-03, ch-04 |
| `openspec/specs/persistence/README.md` | Create | Placeholder ownership ch-04 |
| `openspec/specs/sync-config/README.md` | Create | Placeholder ownership ch-03, ch-05, ch-07 |
| `openspec/specs/ghcr-publishing/README.md` | Create | Placeholder ownership ch-06, ch-07 |
| `openspec/specs/vps-quickstart/README.md` | Create | Placeholder ownership ch-04, ch-05, ch-07 |
| `openspec/ROADMAP.md` | Modify | Estado ch-00 in-progress, gaps actualizados |

## Traceability Matrix

| PRD § | Criterio | Artifact primario | Task / gate | Cambio posterior |
|---|---|---|---|---|
| 502-503 | Encabezado y contexto del bloque; no criterio de aceptación | design | N/A | Ninguno |
| 504 | CI publica imagen multi-arch | spec | ch-06 publish + inspect | ch-07 pins/docs |
| 505 | VPS ARM puede hacer pull y levantar | spec | ch-06 publish + manifest inspect | ch-07 |
| 506 | OpenChamber escucha en puerto y usa password | spec | ch-03 runtime entrypoint | ch-03 |
| 507 | Warning visible si `UI_PASSWORD` vacío | spec | ch-03 runtime entrypoint | ch-03 |
| 508 | Entrypoint inyecta `--ui-password` | design | ch-03 runtime entrypoint | ch-03 |
| 509 | Contenedor incluye stack fijo | spec | ch-02 image build | ch-02, ch-06 |
| 510 | Usuario puede ejecutar `/sync-link` | spec | ch-05 sync docs | ch-05, ch-07 |
| 511 | Persistencia config/state/cache/agents/gh/ssh/workspaces | spec | ch-04 compose persistence | ch-04 |
| 512 | Docs indican límites de sync | spec | ch-05 sync docs | ch-07 |
| 513 | Docs indican stores multi-auth sensibles | spec | ch-05 sync docs | ch-07 |

## Spec Domain Registry

| Domain | Changes | Description |
|---|---|---|
| `container-image` | ch-02, ch-06 | Imagen Docker multi-arch con stack fijo |
| `runtime-config` | ch-02, ch-03, ch-04 | Variables, entrypoint, password, binds |
| `persistence` | ch-04 | Volúmenes host y matriz de mounts |
| `sync-config` | ch-03, ch-05, ch-07 | opencode-synced, seed/merge, límites |
| `ghcr-publishing` | ch-06, ch-07 | CI/CD, tags, manifest inspect, pins |
| `vps-quickstart` | ch-04, ch-05, ch-07 | Compose, .env, docs, troubleshooting |

## Acceptance Gate for ch-00

- [x] Todos los criterios \u00a7502-513 mapeados a spec/design/task.
- [x] Dominios spec candidatos creados en `openspec/specs/` con README de ownership.
- [x] ROADMAP refleja estado `\ud83d\udd04 In Progress` para ch-00 y dominios registrados.
- [x] Ningún archivo de producto (Dockerfile, compose, CI) creado.

## Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Over-scoping: implementar Dockerfile o CI en ch-00 | Med | Alto | Gate explícito: "Ningún archivo de producto creado" |
| Tratar ROADMAP como source of truth | Med | Med | ROADMAP es índice de coordinación; source of truth evolutiva vive en `openspec/specs/` y `openspec/changes/*/specs/` |
| Missing PRD criteria: olvidar \u00a7 o mal clasificar | Med | Alto | Checklist contra \u00a7502-513 y tabla de mapping en design.md |
| Premature implementation: crear tasks para ch-02 antes de tener spec | Low | Med | tasks.md de ch-00 solo cubre formalización; tasks de ch-01..ch-07 se generan en sus respectivas fases |

## Testing Strategy

N/A. Verificación manual contra checklist.

## Migration / Rollout

No migration required.

## Open Questions

- Resuelto: placeholders `README.md` en `openspec/specs/<domain>/` sin `spec.md` hasta cada change.
- Resuelto: por ahora `ROADMAP.md` es índice manual; no existe script `openspec status` en este change.
