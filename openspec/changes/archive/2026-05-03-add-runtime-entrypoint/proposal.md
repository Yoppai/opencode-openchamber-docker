# Proposal: add-runtime-entrypoint

## Intent

Proveer script de arranque (`entrypoint.sh`) que configure OpenChamber al iniciar el contenedor: mapee `UI_PASSWORD`, advierta si falta, y deje lista la config de OpenCode con plugin `opencode-synced` sin destruir configuración existente.

## Scope

### In Scope
- Script `entrypoint.sh` con lógica de arranque.
- Mapeo de `UI_PASSWORD` a flag `--ui-password`.
- Warning visible en logs cuando `UI_PASSWORD` esté vacío.
- Seed/merge de `opencode.jsonc`: crear si no existe, o agregar `opencode-synced` a `plugin[]` sin duplicar ni borrar otros campos.
- Passthrough de variables de entorno runtime soportadas por OpenChamber upstream.
- Ajuste de `Dockerfile` para copiar `entrypoint.sh` y usarlo vía `tini`.

### Out of Scope
- Validación de fortaleza de password.
- Sincronización real de datos vía `opencode-synced` (solo config base).
- Compose ni persistencia de volúmenes (ch-04).
- Documentación formal de ch-02 (se asume Dockerfile ya construido).

## Capabilities

### New Capabilities
- `runtime-entrypoint`: script de arranque del contenedor, mapeo de password, warning, y seed/merge de config OpenCode.

### Modified Capabilities
- `runtime-config`: ahora define comportamiento del entrypoint (antes explícitamente excluía lógica ch-03).

## Approach

- `entrypoint.sh` en shell POSIX, ejecutado por `tini` como ENTRYPOINT.
- Lee `UI_PASSWORD`; si no vacío, acumula `--ui-password "$UI_PASSWORD"`.
- Si vacío, `echo` warning a stderr.
- Resuelve `OPENCHAMBER_CONFIG_DIR` (default `~/.config/openchamber`) para saber dónde vive `opencode.jsonc`.
- Usa `jq` (ya en imagen base Debian) para seed/merge:
  - Si no existe config: escribe config base con `plugin: ["opencode-synced"]`.
  - Si existe: usa `jq` para append único (`index` + `if == null then . + ["opencode-synced"] else . end`).
- Exporta variables upstream y ejecuta `openchamber serve --foreground` con flags acumulados.
- `Dockerfile`: copia `entrypoint.sh`, lo hace ejecutable; ENTRYPOINT queda `tini -- ./entrypoint.sh`.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `entrypoint.sh` | New | Script de arranque runtime. |
| `Dockerfile` | Modified | COPY entrypoint + ajustar ENTRYPOINT/CMD. |
| `openspec/specs/runtime-config/` | Modified | Delta spec: ahora incluye lógica de entrypoint. |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Puerto expuesto en VPS sin password | Med | Warning visible en logs si `UI_PASSWORD` vacío; documentar recomendación fuerte. |
| `opencode-synced` duplicado o config usuario borrada | Low | `jq` con chequeo `index`; solo toca campo `plugin`. |
| Secrets filtrados por config mal generada | Low | Seed/merge nunca escribe secrets ni stores sensibles. |

## Rollback Plan

- Revertir commit que introduce `entrypoint.sh` y modificación de `Dockerfile`.
- Restaurar ENTRYPOINT/CMD anteriores (`tini -- bash`).
- Reconstruir imagen con tag anterior.

## Dependencies

- `ch-02` (`build-container-image`): Dockerfile base con binarios, tini, usuario no-root. Ya implementado; este change lo extiende.

## Success Criteria

- [ ] Contenedor arranca con `UI_PASSWORD` configurado y OpenChamber recibe `--ui-password`.
- [ ] Contenedor arranca con `UI_PASSWORD` vacío, emite warning en logs, y continúa.
- [ ] `opencode.jsonc` se crea si no existe con `opencode-synced` en `plugin`.
- [ ] `opencode.jsonc` existente conserva todos sus campos y `opencode-synced` aparece exactamente una vez.
