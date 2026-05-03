# Design: Spike — Validar Runtime npm de OpenChamber

## Technical Approach

Ejecutar validación empírica de `@openchamber/web` en contenedor limpio basado en `node:22-bookworm-slim`. Pipeline: instalar globalmente → verificar binario en PATH → arrancar servidor con flags CLI → validar password por flag y env var → documentar estado de prebuilds nativas en AMD64 y ARM64 → emitir documento de decisión Go/No-go. Scripts y plantillas de evidencia se versionan; logs generados se depositan en `evidence/`.

## Architecture Decisions

| Decision | Options | Tradeoffs | Choice |
|---|---|---|---|
| Entorno de validación | Docker vs host nativo | Host puede tener estado contaminado; Docker garantiza reproducibilidad y control de arquitectura | Docker con `node:22-bookworm-slim` |
| Multi-arch | QEMU Buildx vs hardware ARM64 nativo | QEMU lento pero disponible en CI; nativo más rápido pero requiere hardware | QEMU Buildx para AMD64+ARM64; usar nativo si está disponible |
| Captura de evidencia | stdout efímero vs archivos estructurados | stdout se pierde; archivos permiten revisión posterior y decisión auditable | Scripts redirigen a `evidence/*.log`; matriz ARM en `evidence/arm-risk-matrix.md` |
| Verificación de password | Inspección de logs vs `curl` a UI | Logs confirman parsing CLI; curl valida comportamiento de usuario real | Primero logs para confirmar flag/env parseados; curl opcional si UI responde en el puerto |
| Fallback ARM nativo | Prebuild vs build-essential | Prebuild es rápido; build-essential suma ~200MB y tiempo de compilación | Validar prebuild primero; documentar `build-essential` + `python3` como mitigación obligatoria para ch-02 |
| npm metadata checks | `npm view` vs `npm pack` vs install directo | `npm view` da metadata sin descargar; `npm pack` permite inspeccionar `package.json` y `bin`; install directo es la verdad final | `npm view` para metadata rápida; `npm pack --dry-run` para validar bin mapping; install global para validación funcional |

## Data Flow

```
node:22-bookworm-slim
    │
    ▼
npm view @openchamber/web@latest
    │
    ├──→ evidence/npm-metadata.log (version, bin, deps, dist-tags)
    │
    ▼
npm install -g @openchamber/web@latest
    │
    ├──→ evidence/install.log
    ├──→ evidence/binary-check.log (which openchamber; openchamber --version)
    │
    ▼
openchamber serve --foreground --host 0.0.0.0 --port 3000
    │
    ├──→ evidence/startup.log
    ├──→ evidence/port-check.log (ss/netstat/nc)
    │
    ▼
Validar password
    │
    ├──→ evidence/password-flag.log (--ui-password)
    ├──→ evidence/password-env.log (OPENCHAMBER_UI_PASSWORD)
    │
    ▼
Verificar prebuilds nativas (better-sqlite3, node-pty, bun-pty)
    │
    ├──→ evidence/arm-risk-matrix.md (amd64 vs arm64 × dep × prebuild/compilado/falla)
    │
    ▼
decisions.md (Go/No-go)
```

## File Changes

| File | Action | Description |
|---|---|---|
| `scripts/validate-install.sh` | Create | Instala globalmente, verifica `openchamber` en PATH y retorna versión |
| `scripts/validate-flags.sh` | Create | Arranca servidor con `--foreground --host --port`; captura startup y verifica bind TCP |
| `scripts/validate-password.sh` | Create | Prueba `--ui-password` y `OPENCHAMBER_UI_PASSWORD`; opcional curl a `/` |
| `scripts/validate-arm.sh` | Create | Inspecciona logs de install para detectar prebuild descargada vs compilación nativa |
| `scripts/check-npm-metadata.sh` | Create | Corre `npm view` y valida que `bin.openchamber` apunte a archivo existente |
| `evidence/.gitkeep` | Create | Directorio para artefactos de evidencia generados en runtime |
| `decisions.md` | Create | Plantilla Go/No-go: flags confirmados, env vars, mitigaciones ARM, bloqueadores |

## Interfaces / Contracts

Ninguna interfaz productiva nueva. Los scripts producen contratos de salida:

- `evidence/npm-metadata.log`: stdout de `npm view --json`, enfocado en `name`, `version`, `bin`, `dependencies`
- `evidence/install.log`: stdout/stderr completo de `npm install -g`; buscar "prebuild" vs "node-gyp" vs "error"
- `evidence/arm-risk-matrix.md`: Tabla con columnas `Plataforma`, `Dependencia`, `Prebuild disponible`, `Compilación requerida`, `Resultado`
- `decisions.md`: Estructura fija con secciones obligatorias: `Estado (Go/No-go)`, `Flags CLI Confirmados`, `Variables de Entorno Requeridas`, `Mitigaciones ARM64`, `Bloqueadores y Remediación`

## Testing Strategy

| Layer | What to Test | Approach |
|---|---|---|
| Smoke | Binario expuesto, servidor arranca, puerto responde | Scripts shell en contenedor limpio; `set -euo pipefail`; timeout para startup |
| Password | Flag CLI y env var son respetados por el proceso | Assert en logs ("password enabled") o curl con credenciales |
| ARM | better-sqlite3, node-pty, bun-pty resuelven sin compilación | Build multi-arch con Buildx; grep de install output por "prebuild" vs "gyp" |
| Metadata | Paquete publica binario correcto y versión esperada | `npm view` + assert `bin.openchamber` exists in tarball |

## Migration / Rollout

No migration required. Spike es destruible; ningún cambio productivo.

## Open Questions

- [ ] ¿Hardware ARM64 nativo disponible para validación real? Fallback a QEMU.
- [ ] ¿`curl` está presente en `node:22-bookworm-slim` o requiere `apt-get install curl`? Prever instalación transient en script.
