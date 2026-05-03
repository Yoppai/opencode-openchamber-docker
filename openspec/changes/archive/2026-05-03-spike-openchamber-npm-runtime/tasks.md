# Tasks: Spike — Validar Runtime npm de OpenChamber

## Phase 1: Foundation

- [x] 1.1 Crear `evidence/.gitkeep` para artefactos de runtime.
- [x] 1.2 Crear `scripts/check-npm-metadata.sh` que ejecute `npm view --json` sobre `@openchamber/web@latest`, valide `bin.openchamber` y guarde en `evidence/npm-metadata.log`.
- [x] 1.3 Crear `scripts/validate-install.sh` en contenedor `node:22-bookworm-slim`: instala globalmente, verifica `which openchamber` y `openchamber --version`, redirige a `evidence/install.log` y `evidence/binary-check.log`.

## Phase 2: Core Runtime Validation

- [x] 2.1 Crear `scripts/validate-flags.sh`: arranca `openchamber serve --foreground --host 0.0.0.0 --port 3000`, captura startup en `evidence/startup.log`, verifica bind TCP en `evidence/port-check.log` (ss/netstat/nc), y prueba comando default sin subcomando.
- [x] 2.2 Crear `scripts/validate-password.sh`: inicia con `--ui-password secret123`, captura log en `evidence/password-flag.log`; repite con `OPENCHAMBER_UI_PASSWORD=envpass` en `evidence/password-env.log`; opcional curl a `/`.

## Phase 3: ARM64 Risk Matrix

- [x] 3.1 Crear `scripts/validate-arm.sh` multi-arquitectura (AMD64 + ARM64 via QEMU Buildx o nativo): ejecuta install global, inspecciona `evidence/install.log` por "prebuild" vs "node-gyp" vs "error".
- [x] 3.2 Generar `evidence/arm-risk-matrix.md` con columnas: Plataforma, Dependencia (`better-sqlite3`, `node-pty`, `bun-pty`), Prebuild disponible, Compilación requerida, Resultado.

## Phase 4: Decision Document

- [x] 4.1 Crear plantilla `decisions.md` con secciones obligatorias: Estado (Go/No-go), Flags CLI Confirmados, Variables de Entorno Requeridas, Mitigaciones ARM64, Bloqueadores y Remediación.
- [x] 4.2 Poblar `decisions.md` con resultados de evidencia; declarar Go si pasan binario, flags, password y prebuilds documentadas; declarar No-go con bloqueadores si falla algo crítico.

## Verification Checklist (mapped to spec)

| Req | Scenario | Evidence File | Pass Criteria | Status |
|---|---|---|---|---|
| R1 | Instalación global expone binario | `evidence/binary-check.log` | `openchamber --version` retorna versión no vacía | ✅ PASA — version=1.9.10 en PATH |
| R2 | Servidor foreground en host/port | `evidence/startup.log`, `evidence/port-check.log` | Proceso no sale; puerto 3000 en 0.0.0.0 | ❌ BLOQUEADO — openchamber requiere opencode CLI |
| R2 | Comando default sin subcomando | `evidence/startup.log` | Arranca como `serve` | ❌ BLOQUEADO — openchamber requiere opencode CLI |
| R3 | Password por flag CLI | `evidence/password-flag.log` | Log indica password activo o curl 401/200 | ❌ BLOQUEADO — serve no arranca sin opencode |
| R3 | Password por env var | `evidence/password-env.log` | `OPENCHAMBER_UI_PASSWORD` respetado | ❌ BLOQUEADO — serve no arranca sin opencode |
| R4 | Prebuilds AMD64 | `evidence/install.log` | `better-sqlite3`, `node-pty` sin `node-gyp` | ✅ PASA — 0 node-gyp, prebuild-install usado |
| R4 | Riesgo ARM64 documentado | `evidence/arm-risk-matrix.md` | Tabla completa; fallback `build-essential` + `python3` anotado | ✅ PASA — matriz actualizada con datos QEMU |
| R5 | Decisión Go/No-go | `decisions.md` | Estado explícito, flags, env vars, mitigaciones, bloqueadores | ✅ NO-GO — requiere opencode runtime |

## Runtime Fixes (Docker activo)

1. **scripts/check-npm-metadata.sh** — Reemplazado `readFileSync('/dev/stdin')` por `readFileSync(process.argv[1])` para compatibilidad con pipes en Docker.
2. **scripts/validate-flags.sh** — Añadida detección de proceso muerto inmediato (`kill -0` check antes de `wait_for_port`); documenta "opencode dependency" en evidencia.
3. **scripts/validate-password.sh** — Añadida detección de proceso muerto inmediato en escenarios 1 y 2; estructura `if/else/fi` anidada corregida.
4. **scripts/validate-arm.sh** — `detect_dep_status` ahora usa `install.log` raw en vez de `arm-install-amd64.log` (análisis). No sobrescribe `arm-install-arm64.log` existente con "NOT TESTED".

## Hallazgos Runtime Clave

1. **CRITICAL: openchamber requiere opencode CLI en PATH** — Sin opencode, ningún subcomando funciona (serve, default, password). `openchamber --version` es la única operación que no requiere opencode.
2. **Prebuilds funcionan en AMD64 y ARM64** — `better-sqlite3`, `node-pty`, `bun-pty` instalados sin `node-gyp` en ambas arquitecturas. `prebuild-install@7.1.3` usado (deprecado).
3. **ARM64 via QEMU funcional** — Instalación completa de 243 paquetes en ~47s (vs 11s AMD64). Diferencia es overhead QEMU, no compilación.
4. **Evidencia de seguridad no obtenible** — Password enforcement no puede verificarse sin `openchamber serve`.

## Notas de Ejecución

- **Host:** Windows (PowerShell), Docker Desktop v28.3.2
- **Docker daemon:** ✅ Activo
- **Contenedor:** `node:22-bookworm-slim` (AMD64 nativo, ARM64 via QEMU)
- **npm metadata:** `@openchamber/web@1.9.10`, `bin.openchamber = bin/cli.js` ✅
- **openchamber serve:** ❌ Bloqueado — requiere `opencode` CLI en PATH
- **Comando para validación futura (cuando opencode esté disponible):**
  ```
  docker run --rm -v "$(pwd):/workspace" -w /workspace node:22-bookworm-slim bash -lc '
    set -euo pipefail
    bash scripts/check-npm-metadata.sh
    bash scripts/validate-install.sh
    bash scripts/validate-flags.sh
    bash scripts/validate-password.sh
    bash scripts/validate-arm.sh
  '
  ```
