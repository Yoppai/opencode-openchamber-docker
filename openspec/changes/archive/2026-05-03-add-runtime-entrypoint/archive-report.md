# Archive Report: add-runtime-entrypoint (ch-03)

**Archived**: 2026-05-03
**Verdict**: PASS WITH WARNINGS
**Artifact store**: hybrid

## Summary

Change `add-runtime-entrypoint` implementó entrypoint script para contenedor OpenChamber: mapeo de `UI_PASSWORD`, warning si vacío, seed/merge idempotente de `opencode-synced` en config OpenCode, y `exec openchamber serve --foreground` vía `tini`.

## Specs Synced

| Domain | Action | Details |
|--------|--------|---------|
| `runtime-config` | Updated | Delta merge: 1 requirement MODIFIED (text unchanged), 2 ADDED ("Entrypoint como punto de arranque del contenedor" con 5 escenarios, "Resolución de directorio de configuración" con 1 escenario) |
| `sync-config` | Created | NEW main spec: 4 requirements (creación base, merge sin destruir, no duplicación, operación JSONC segura) |

### runtime-config Delta Merge

| Requirement | Action |
|-------------|--------|
| Usuario no-root | Preserved (not in delta) |
| Entorno limpio sin responsabilidades de ch-03 | Unchanged (text identical) |
| Entrypoint como punto de arranque del contenedor | ADDED (5 scenarios) |
| Resolución de directorio de configuración | ADDED (1 scenario) |

## Archive Contents

- `proposal.md` ✅
- `specs/runtime-config/spec.md` ✅
- `specs/sync-config/spec.md` ✅
- `design.md` ✅
- `tasks.md` ✅ (14/14 tasks complete)
- `verify-report.md` ✅
- `archive-report.md` ✅

## Warnings / Known Deviations

Documented in verify-report, accepted for archive:

1. **Config dir spec mismatch**: Delta spec `runtime-config` dice default `~/.config/openchamber`. Implementación usa `$HOME/.config/opencode` (OpenCode config dir). Spec NO corregido — queda como desviación conocida. Recomendado: actualizar spec en ch-04 o ch-05.

2. **JSONC comments preservados solo en no-op**: `grep-first` evita modificar archivos donde `opencode-synced` ya existe, preservando comments. Si falta plugin y JSONC tiene comments, `jq` falla y restaura original. No hay corrupción pero tampoco merge exitoso. Tradeoff documentado.

3. **PID scenario vs exec design**: Escenario dice "hijo directo es entrypoint script". Implementación usa `exec`, entonces hijo de `tini` es `openchamber`. Diseño favorece señalización correcta. Spec debería reflejar semántica `exec`.

4. **Scenario ch-02 en delta ch-03**: Escenario "imagen ch-02 sin lógica ch-03" no aplica a imagen ch-03 actual. Se mantiene en main spec como registro histórico.

5. **ShellCheck no reproducible**: No instalado en entorno de verify. Tarea 3.1 afirma ejecutado previamente.

## SDD Cycle Complete

Change fully planned, implemented, verified (PASS WITH WARNINGS), and archived.
Ready for ch-04 `add-compose-persistence`.
