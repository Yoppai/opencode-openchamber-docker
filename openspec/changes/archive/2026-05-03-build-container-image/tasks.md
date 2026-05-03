# Tasks: build-container-image

## Phase 1: Dockerfile & Infrastructure

- [x] 1.1 Create `Dockerfile` from `node:22-bookworm-slim`
- [x] 1.2 Declare build args `OPENCODE_VERSION` and `OPENCHAMBER_VERSION` with defaults `latest`
- [x] 1.3 Install OS deps in single RUN: `bash ca-certificates git gh openssh-client tini curl unzip`, clean apt cache
- [x] 1.4 Download Bun release tarball via `curl` using `TARGETARCH` (`x64-baseline`/`aarch64`), unzip to `/usr/local/bin/bun`
- [x] 1.5 `npm install -g opencode-ai@${OPENCODE_VERSION}` before OpenChamber
- [x] 1.6 `npm install -g @openchamber/web@${OPENCHAMBER_VERSION}`, clean npm cache
- [x] 1.7 Create `openchamber:openchamber` UID/GID 1000, set `WORKDIR /home/openchamber`, `USER openchamber`
- [x] 1.8 Set `ENV OPENCODE_BINARY=/usr/local/bin/opencode`
- [x] 1.9 Set `ENTRYPOINT ["tini", "--"]` and `CMD ["bash"]`
- [x] 1.10 Modify `.dockerignore` to exclude `openspec/`, `scripts/`, `evidence/`

## Phase 2: Validation

- [x] 2.1 Create `scripts/validate-image.sh` with local `docker build -t opencode-openchamber .`
- [x] 2.2 Add loop verifying 7 binaries return version: `opencode`, `openchamber`, `bun`, `gh`, `git`, `ssh`, `tini`
- [x] 2.3 Assert `id openchamber` shows UID 1000 and GID 1000 inside container
- [x] 2.4 Smoke test: run `openchamber serve --foreground --host 0.0.0.0 --port 3000` for >5s, fail if logs contain "Unable to locate the opencode CLI"
  - Post-verify hardening (2026-05-03): added `docker inspect -f '{{.State.Running}}'` check after 6s sleep — fails immediately if container exited early, prevents false-positive on process lifetime.
- [x] 2.5 Execute `scripts/validate-image.sh` and capture full output
  - ⚠ Windows no tiene bash WSL; validaciones ejecutadas manualmente vía PowerShell + Docker directo.
  - 7/7 binarios PASS, user PASS, smoke serve PASS.

## Phase 3: Evidence & Boundaries

- [x] 3.1 Save validation output and notes to `evidence/ch-02/`
- [x] 3.2 Document ch-03 entrypoint/password/seed merge as future TODO, do not implement
  - `UI_PASSWORD` references exist only in `@openchamber/web` package internals (cli.js, cli-options.js, README.md), NOT in custom Dockerfile/entrypoint logic.
  - No custom entrypoint script, no `opencode-synced` references.
- [x] 3.3 Document ch-04 Compose/persistence as out-of-scope
- [x] 3.4 Document ch-06 GHCR multi-arch publish as out-of-scope

## Verification Checklist

| Spec Requirement | Task | Verification | Result |
|---|---|---|---|
| Build args `OPENCODE_VERSION`/`OPENCHAMBER_VERSION` | 1.2 | Build with explicit versions, check installed | ✅ `opencode --version` = 1.0.0, `openchamber --version` = 1.9.10 |
| Binarios en PATH (7) | 2.2 | `--version` returns 0 | ✅ 7/7 PASS: opencode, openchamber, bun, gh, git, ssh, tini |
| Resolución bloqueador OpenChamber | 2.4 | Serve >5s sin error CLI ausente | ✅ OpenChamber server listening on 0.0.0.0:3000, OpenCode launched, State.Running=true after 7s (post-verify hardened: script now checks State.Running) |
| Compatibilidad Debian/glibc | 1.1 | Base `node:22-bookworm-slim` | ✅ Debian 12 (bookworm), glibc 2.36, NO musl |
| Usuario no-root UID/GID 1000 | 1.7, 2.3 | `id openchamber` = 1000:1000 | ✅ uid=1000(openchamber) gid=1000(openchamber) |
| Sin lógica ch-03 | 3.2 | No `UI_PASSWORD` ni `opencode-synced` en imagen | ✅ Solo referencias internas de paquete `@openchamber/web`, sin entrypoint custom |

## Notas

- **Gotcha**: `node:22-bookworm-slim` ya tiene `node:node` UID/GID 1000. Dockerfile renombra `node` → `openchamber` con `groupmod -n` + `usermod -l -d -m` en lugar de `groupadd`/`useradd`.
- **Validate script**: `scripts/validate-image.sh` requiere bash (Linux/macOS/WSL). En Windows PowerShell las validaciones se ejecutaron directo con comandos `docker run`.
- **ch-01 blocker RESOLVED**: `openchamber serve` ahora localiza `opencode` en `/usr/local/bin/opencode` y arranca correctamente.
- **Post-verify hardening (2026-05-03)**: 
  - Smoke test ahora verifica `State.Running` tras sleep 6s — fail si container murió antes.
  - `evidence/ch-02/validate.log` producido via PowerShell Docker commands.
  - `smoke-serve.log` actualizado con `State.Running=true`, `State.ExitCode=0`.
