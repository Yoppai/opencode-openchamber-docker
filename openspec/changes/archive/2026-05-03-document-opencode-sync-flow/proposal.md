# Proposal: Documentar Flujo opencode-synced

## Intent

Usuarios que despliegan OpenChamber en VPS no tienen guía para sincronizar su configuración local OpenCode. La mecánica ya existe (seed/merge en entrypoint.sh, volúmenes en docker-compose.yml, gh/git/jq instalados), pero falta documentación de usuario. Este cambio cierra esa brecha.

## Scope

### In Scope
- Documentar flujo `/sync-init` (local) → `/sync-link <repo>` (VPS)
- Documentar qué sincroniza vs qué no: config/plugins/skills/agents ✅; secrets/sessions/stores ❌
- Advertencias de seguridad: `includeSecrets false`, sesiones = riesgo conflicto Git, tokens multi-auth
- Diferencia entre persistencia por volumen y sync por Git
- Turso como recomendación para sesiones multi-máquina
- `extraSecretPaths` opt-in con repo privado

### Out of Scope (Non-goals)
- Cambios de código (seed/merge implementado en ch-04)
- Nuevas features de sync
- Modificar comportamiento de `opencode-synced`

## Capabilities

### New Capabilities
None — cambio puramente documental, sin nuevos comportamientos.

### Modified Capabilities
None — no se modifican requisitos de specs existentes.

## Approach

Escribir documentación de usuario que:
1. Explique el flujo paso a paso
2. Liste exclusiones por default con razones de seguridad
3. Contraste volúmenes Docker (persistencia local VPS) vs Git sync (replicación cross-machine)
4. Incluya warning blocks para secrets y sessions
5. Mencione Turso y `extraSecretPaths` como avanzado

La documentación residirá en README.md raíz o sección dedicada.

## Affected Areas

| Área | Impacto | Descripción |
|------|---------|-------------|
| `README.md` (nuevo o actualizado) | Nuevo | Documentación principal de sync |
| `openspec/specs/sync-config/spec.md` | Referencia | Documentación enlaza a spec técnico |
| `openspec/specs/vps-quickstart/spec.md` | Referencia | Documentación enlaza a bootstrap VPS |

## Risks

| Riesgo | Probabilidad | Mitigación |
|--------|--------------|------------|
| Documentación obsoleta cuando cambie upstream | Med | Revisar docs en cada release de opencode-synced |
| Usuario confunde volumen con Git sync | Med | Tabla comparativa explícita en docs |

## Rollback Plan

Eliminar archivos de documentación añadidos. Revertir commits de docs. No afecta runtime.

## Dependencies

- ch-04 (archivado ✅) — seed/merge implementado
- `openspec/specs/sync-config/spec.md` — comportamiento técnico documentado
- `openspec/specs/vps-quickstart/spec.md` — bootstrap VPS documentado

## Success Criteria

- [ ] Usuario nuevo puede seguir flujo sync sin preguntar
- [ ] Qué no sincroniza está claro con justificación de seguridad
- [ ] Diferencia volumen vs Git sync explicada
- [ ] Turso y `extraSecretPaths` documentados como opt-in

## PRD Traceability

| PRD Section | Tema |
|-------------|------|
| §176-239 | opencode-synced: qué sincroniza, seed/merge, flujo esperado |
| §306-313 | Sincronización: `/sync-init`, `/sync-link`, `GH_TOKEN`, plugin base |
| §341-349 | Seguridad: `includeSecrets`, `includeSessions`, stores sensibles, `extraSecretPaths` |
