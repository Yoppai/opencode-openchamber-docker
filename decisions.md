# Decision Document: OpenChamber Runtime Validation

## Estado (Go / No-go)

**Decisión:** **NO-GO para ch-02 — `openchamber serve` requiere `opencode` CLI en PATH**

**Hallazgos runtime (Docker activo — node:22-bookworm-slim):**
- ✅ `@openchamber/web@1.9.10` — npm metadata y `bin.openchamber = bin/cli.js` confirmado
- ✅ `npm install -g @openchamber/web@latest` — 243 paquetes instalados en ~11s
- ✅ `/usr/local/bin/openchamber` expuesto en PATH después de install global
- ✅ `openchamber --version` = `1.9.10`
- ✅ `npm pack --dry-run` confirma `bin/cli.js` en tarball (306 archivos, 27.1MB)
- ✅ ARM64 via QEMU: instalación completa sin errores (~47s, overhead de emulación)
- ✅ No se detectó `node-gyp` ni compilación nativa en AMD64 ni ARM64 (prebuilds disponibles)
- ❌ **`openchamber serve` bloqueado** — requiere `opencode` CLI en PATH
- ❌ `openchamber --foreground` sin subcomando — también requiere `opencode`
- ❌ `--ui-password` y `OPENCHAMBER_UI_PASSWORD` — no verificables sin `openchamber serve`
- ❌ Evidencia de autenticación HTTP — no obtenible sin servidor corriendo

---

## Flags CLI Confirmados

| Flag | Esperado | Resultado | Evidencia |
|---|---|---|---|
| `--foreground` | Proceso no daemoniza | ⚠️ BLOQUEADO — requiere opencode | `evidence/startup.log` |
| `--host <ip>` | Bind a dirección específica | ⚠️ BLOQUEADO — requiere opencode | `evidence/startup.log` |
| `--port <n>` | Puerto TCP específico | ⚠️ BLOQUEADO — requiere opencode | `evidence/port-check.log` |
| `--ui-password <s>` | Password para UI web | ⚠️ BLOQUEADO — requiere opencode | `evidence/password-flag.log` |
| Sin subcomando | Default a `serve` | ⚠️ BLOQUEADO — requiere opencode | `evidence/startup.log` |

## Variables de Entorno Requeridas

| Variable | Mapeo | Resultado | Evidencia |
|---|---|---|---|
| `OPENCHAMBER_UI_PASSWORD` | `--ui-password` | ⚠️ BLOQUEADO — requiere opencode | `evidence/password-env.log` |
| `OPENCODE_BINARY` | Ruta a opencode CLI | ❌ No configurada (causa del bloqueo) | `evidence/opencode-dependency.log` |

## Mitigaciones ARM64

| Dependencia | AMD64 Prebuild | ARM64 Prebuild | Acción Requerida en ch-02 |
|---|---|---|---|
| `better-sqlite3 ^11.7.0` | ✅ Prebuild (no se detectó node-gyp) | ✅ Prebuild (no se detectó node-gyp) | Ninguna — prebuilds disponibles |
| `node-pty 1.2.0-beta.12` | ✅ Prebuild (no se detectó node-gyp) | ✅ Prebuild (no se detectó node-gyp) | Ninguna — prebuilds disponibles |
| `bun-pty ^0.4.5` | ✅ Prebuild (no se detectó node-gyp) | ✅ Prebuild (no se detectó node-gyp) | Ninguna — prebuilds disponibles |

**Nota:** `prebuild-install@7.1.3` utilizado (deprecado). Monitorear migración a `@prebuild/core`.

**Mitigación general:** Si alguna dependencia requiere compilación en ARM64, agregar al Dockerfile:

```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    python3 \
    && rm -rf /var/lib/apt/lists/*
```

## Bloqueadores y Remediación

| # | Bloqueador | Severidad | Evidencia | Remediación |
|---|---|---|---|---|
| 1 | `openchamber serve` requiere `opencode` CLI en PATH | **CRITICAL** | `evidence/opencode-dependency.log`, `evidence/startup.log` | Instalar `opencode` CLI en el contenedor de producción o setear `OPENCODE_BINARY` |
| 2 | Flags CLI y password no verificables sin serve | High | `evidence/password-flag.log`, `evidence/password-env.log` | Resolver #1 primero |
| 3 | `prebuild-install@7.1.3` deprecado | Low | `evidence/install.log` line 2 | Monitorear; npm 11+ puede requerir `@prebuild/core` |

---

## Recomendación para ch-02

1. **Agregar `opencode` CLI** al contenedor — instalarlo via npm global o binario precompilado
2. **Setear `OPENCODE_BINARY`** env var si opencode está en ubicación no estándar
3. **No se requiere `build-essential`** — prebuilds disponibles para AMD64 y ARM64
4. **Probar `openchamber serve`** con opencode presente para validar flags y password
5. **Re-evaluar Go** cuando `openchamber serve` funcione y auth HTTP sea verificable

---

## Metadatos

- **Spike:** spike-openchamber-npm-runtime
- **Fecha ejecución runtime:** 2026-05-03
- **Entorno:** Docker v28.3.2 (Docker Desktop), node:22-bookworm-slim
- **Arquitectura nativa:** x86_64 (AMD64), ARM64 via QEMU
- **Versión @openchamber/web:** 1.9.10 (confirmado)
- **npm metadata:** `bin.openchamber = bin/cli.js` — ✅ PASA
- **Instalación global:** ✅ PASA
- **Flags CLI / Password:** ❌ BLOQUEADO (opencode dependency)
- **Prebuilds ARM64:** ✅ PASA (sin compilación nativa)
