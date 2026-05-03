# Design: build-container-image

## Technical Approach

Dockerfile single-stage desde `node:22-bookworm-slim`. Instalar deps OS, Bun vía release tarball oficial, OpenCode (`opencode-ai`) y OpenChamber (`@openchamber/web`) en orden fijo. Crear usuario `openchamber` 1000:1000. Validar localmente con `docker build` + smoke test de `openchamber serve` verificando que no falle por `opencode` ausente. Diferir entrypoint completo a ch-03.

## Architecture Decisions

| Decision | Opciones | Tradeoffs | Elección |
|---|---|---|---|
| Single-stage vs multi-stage | Multi-stage copia `/usr/local/lib/node_modules` y symlinks | Menor tamaño, pero riesgo de romper native modules (`better-sqlite3`, `node-pty`, `bun-pty`) al copiar entre stages | Single-stage. Cache apt/npm limpiada en misma RUN. Tradeoff: ~50-100MB extra por simplicidad y seguridad de native bindings |
| Instalación Bun | `npm install -g bun` vs curl tar/zip oficial | npm es más simple pero puede no ser el release exacto; tar/zip es descarga controlada sin bash pipe | Tar/zip oficial desde GitHub releases usando `TARGETARCH` (`x64-baseline`/`aarch64`). Instalar `curl`+`unzip` transientes |
| Resolución opencode | Solo PATH vs PATH + `OPENCODE_BINARY` | PATH debería bastar, pero ch-01 demostró que `openchamber serve` falla si no encuentra CLI | Instalar `opencode-ai` global primero, verificar que `/usr/local/bin/opencode` existe. Setear `ENV OPENCODE_BINARY=/usr/local/bin/opencode` como defensa adicional |
| Usuario runtime | root vs openchamber 1000 | root es más simple; no-root es requisito de seguridad del PRD | Crear `openchamber:openchamber` UID/GID 1000. `USER openchamber` al final del Dockerfile |
| Entrypoint ch-02 | Ninguno vs `tini -- bash` vs script propio | Ninguno deja señales sin manejar; `tini` es requisito del stack; script propio violaría límite con ch-03 | `ENTRYPOINT ["tini", "--"]` + `CMD ["bash"]` . ch-03 reemplazará CMD por script de arranque con password/sync |

## Data Flow

```
Dockerfile
  ├── RUN apt-get install bash ca-certificates git gh openssh-client tini curl unzip
  ├── RUN descargar bun-linux-<arch>.zip → /usr/local/bin/bun
  ├── RUN npm install -g opencode-ai@${OPENCODE_VERSION}
  ├── RUN npm install -g @openchamber/web@${OPENCHAMBER_VERSION}
  ├── RUN groupadd/useradd openchamber 1000
  ├── ENV OPENCODE_BINARY=/usr/local/bin/opencode
  ├── WORKDIR /home/openchamber
  └── USER openchamber

validate-image.sh
  ├── docker build
  ├── docker run <bin> --version (x7)
  ├── id openchamber | grep uid=1000
  └── docker run openchamber serve --foreground ... → sleep 6 → grep blocker
```

## File Changes

| File | Action | Description |
|---|---|---|
| `Dockerfile` | Create | Definición imagen producción single-stage |
| `scripts/validate-image.sh` | Create | Build local + versiones + usuario + smoke serve |
| `.dockerignore` | Modify | Añadir `openspec/`, `scripts/`, `evidence/` para reducir contexto de build |

## Interfaces / Contracts

Build args:
- `OPENCODE_VERSION` (default `latest`)
- `OPENCHAMBER_VERSION` (default `latest`)
- `TARGETARCH` (inyectado por Buildx)

Env expuestos:
- `OPENCODE_BINARY=/usr/local/bin/opencode`
- `PATH` heredado de base image con `/usr/local/bin` garantizado

## Testing Strategy

| Layer | What | Approach |
|---|---|---|
| Build | `docker build` exitoso local | Ejecutar en host con Docker Desktop/Daemon |
| Binarios | 7 comandos retornan `--version` sin error | Loop en `validate-image.sh` |
| Usuario | UID/GID 1000 | `id openchamber` dentro del contenedor |
| Smoke | `openchamber serve` >5s sin error de CLI ausente | `docker run` con timeout 6s; assert en logs que no aparezca "Unable to locate the opencode CLI" |

## Migration / Rollout

No migration. Imagen nueva; rollback es eliminar `Dockerfile`, `scripts/validate-image.sh` y revertir `.dockerignore`.

## Open Questions

- ¿Bun release URL `latest/download/` es estable o debe pinnearse a versión exacta? Para ch-02 usamos `latest`; ch-06 puede definir `BUN_VERSION` build arg.
- ¿`OPENCODE_BINARY` es leído por OpenChamber o solo `PATH`? La defensa doble cubre ambos casos, pero convendría verificar en ch-03 si la variable es redundante.
