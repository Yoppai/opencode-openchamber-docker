## Exploration: spike-openchamber-npm-runtime

### Current State

PRD y ROADMAP definen `@openchamber/web` como paquete npm para instalar OpenChamber en imagen Docker. ch-00 (formalize-docker-roadmap) archivado. Sin validación real del binario, flags, ni deps nativas. Este spike cierra gap #3 del inventario ROADMAP.

### Sources Investigated

| Source | What found |
|--------|------------|
| `registry.npmjs.org/@openchamber/web` | Package v1.9.10 exists. `bin.openchamber` → `bin/cli.js`. Deps incluyen `better-sqlite3`, `node-pty`, `bun-pty` |
| `github.com/openchamber/openchamber` | Repo fuente. Dockerfile upstream usa `oven/bun:1`, build desde source. Entrypoint mapea `UI_PASSWORD` → `--ui-password` |
| `packages/web/bin/cli.js` (upstream) | Parsing completo de flags. `serve` es default command. `--foreground`, `--host`, `--port`, `--ui-password` confirmados |
| `packages/web/server/index.js` (upstream) | `main()` recibe `uiPassword`, `host`, `port` desde CLI; monta Express, OpenCode lifecycle, auth |
| `scripts/docker-entrypoint.sh` (upstream) | Entrypoint: SSH key gen, `UI_PASSWORD` env → `--ui-password`, `OPENCHAMBER_HOST` default `0.0.0.0` en Docker |

### Affected Areas

- `openspec/changes/spike-openchamber-npm-runtime/` — Nueva. Artefactos de este spike
- `openspec/specs/container-image/` — Los findings de este spike alimentan spec de ch-02
- `openspec/specs/runtime-config/` — Flags validados informan entrypoint design
- `openspec/ROADMAP.md` — Gap #3 (runtime no validado) se cierra con ch-01

### CLI Flags Validation

| Flag / Env Var | Status | Detalle |
|---|---|---|
| `openchamber` binary | ✅ | `@openchamber/web` publica `bin/cli.js` |
| `openchamber serve` | ✅ | Default command si no se pasa subcommand |
| `--foreground` / `--no-daemon` | ✅ | Server en foreground (no fork). Usar para systemd/process managers |
| `--host` / `OPENCHAMBER_HOST` | ✅ | Bind address. Default `127.0.0.1`. Docker entrypoint upstream setea `0.0.0.0` |
| `--port` / `-p` / `OPENCHAMBER_PORT` | ✅ | Default 3000 |
| `--ui-password` / `OPENCHAMBER_UI_PASSWORD` | ✅ | `OPENCHAMBER_UI_PASSWORD` es fallback interno del CLI. `UI_PASSWORD` no lo lee el CLI directamente |
| `UI_PASSWORD` env var | ✅ | Entrypoint upstream mapea → `--ui-password "$UI_PASSWORD"` |
| `--json`, `--quiet`, `-q` | ✅ | Output modes |
| Daemon mode (default) | ✅ | Sin `--foreground`, fork child process. Con foreground, atento a señales |

### Runtime Dependencies Analysis

| Dep | Version | Native? | ARM risk | Notes |
|-----|---------|---------|----------|-------|
| `better-sqlite3` | ^11.7.0 | ✅ N-API C++ | Bajo | Prebuilt ARM64 desde v11. Fallback: `build-essential`, `python3` |
| `node-pty` | 1.2.0-beta.12 | ✅ N-API C++ | Medio | Beta. ARM prebuilt coverage incierto. `build-essential` como fallback |
| `bun-pty` | ^0.4.5 | ✅ | Bajo | Solo usado si runtime Bun detectado. Bajo Node.js: instalado pero ocioso |
| `simple-git` | ^3.28.0 | No | Ninguno | Pure JS |
| `ws` | ^8.18.3 | No | Ninguno | Pure JS |
| `express`, `compression`, `jose`, etc. | varias | No | Ninguno | Pure JS |

### Key Divergence: Upstream vs Our Approach

| Aspect | Upstream Dockerfile | Our Planned Approach | Impact |
|--------|-------------------|---------------------|--------|
| Base image | `oven/bun:1` | `node:22-bookworm-slim` | Need Bun installed for preferred runtime |
| Build method | Source monorepo (`bun run build:web`) | `npm install -g @openchamber/web` | Simpler but may miss edge cases |
| Runtime | Bun (primary) | Bun (preferred) or Node.js (fallback) | `getPreferredServerRuntime()` returns Bun if available |
| Node.js | Installed separately | Base image already has Node.js | OK |
| npm prefix | Custom `/home/openchamber/.npm-global` | Global install `-g` | Different PATH management |

### Approaches

1. **npm install + Node.js runtime** (minimal)
   - Pros: Menos deps (no Bun), menor imagen, `#!/usr/bin/env node` funciona
   - Cons: CLI prefiere Bun via `getPreferredServerRuntime()`. Terminal via `node-pty` funciona en Node. Rendimiento PTY mejor con Bun
   - Effort: Low

2. **npm install + Bun runtime** (approach upstream)
   - Pros: CLI runtime preferido. PTY performance mejor. Alineado con upstream
   - Cons: Bun ≈ 100MB extra en imagen. `node:22-bookworm-slim` + Bun install
   - Effort: Medium

3. **npm install + both runtimes** (resilient)
   - Pros: OpenChamber usa Bun, OpenCode usa Node.js. Ambos disponibles para plugins
   - Cons: Mayor tamaño imagen. Más complejidad
   - Effort: Medium

### Recommendation

Approach 2 (npm install + Bun runtime). OpenChamber upstream corre en Bun, `getPreferredServerRuntime()` prefiere Bun, y `bun-pty` / `node-pty` tienen mejor soporte con Bun. Instalar Bun en runtime stage vía script oficial sobre `node:22-bookworm-slim`. Esto mantiene Node.js disponible para OpenCode y npm.

### Risks

- **ARM better-sqlite3**: Prebuilt ARM64 disponible, pero `build-essential` + `python3` necesarios como fallback en Dockerfile
- **node-pty beta ARM**: 1.2.0-beta.12 puede no tener prebuilt ARM64. Test real post-spike
- **Bun install**: Script curl-pipe, contraviene non-goal "no depender de curl bash". Alternativa: descargar .deb o .tar.gz desde releases
- **CLI daemon mode**: `--foreground` necesario para systemd; default es daemon que fork. Nuestro entrypoint debe pasar `--foreground`
- **OpenChamber needs Bun**: Sin Bun, `getPreferredServerRuntime()` fallback a Node.js pero terminal/PTY performance puede degradar
- **npm shrinkwrap**: OpenChamber deps nativas compilan en install; prebuilds dependen de plataforma. ARM sin build tools = fail

### Ready for Proposal

Sí. Todos los flags validados contra fuente. Riesgos ARM identificados con mitigaciones. Próximo paso: sdd-propose → sdd-spec → sdd-design → sdd-tasks para ch-02 build.
