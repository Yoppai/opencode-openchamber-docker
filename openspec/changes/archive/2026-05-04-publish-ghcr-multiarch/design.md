# Design: Publish GHCR Multi-Arch

## Technical Approach

Workflow único `.github/workflows/publish.yml` que corre en push a `main`, tags `v*`, y `workflow_dispatch`. Usa QEMU + Buildx para compilar `linux/amd64` y `linux/arm64` en paralelo. Pushea a GHCR con tags mínimos. Post-push valida manifest con `docker buildx imagetools inspect`. `docker-compose.yml` activa referencia GHCR. Sin cache de build para MVP.

## Architecture Decisions

| ID | Decision | Choice | Alternatives rejected | Rationale |
|---|---|---|---|---|
| AD1 | Single vs multi-workflow | Single `publish.yml` con lógica condicional de tags | Un workflow por trigger | Menos archivos, build consistente, mantenimiento simple |
| AD2 | Auth token | `GITHUB_TOKEN` con `packages: write` | PAT manual | Auto-rotado, scope de repo, sin overhead de secrets |
| AD3 | QEMU setup | `docker/setup-qemu-action@v3` | Instalar qemu manualmente en runner | Action oficial, binfmt registration cross-platform |
| AD4 | Buildx driver | `docker/setup-buildx-action@v3` default driver | docker-container / kubernetes driver | Docker driver suficiente para este proyecto |
| AD5 | Build action | `docker/build-push-action@v6` | `docker buildx build` raw en shell | Action madura: args, tags, plataformas y push en un paso |
| AD6 | Tag computation | Expresiones GitHub Actions + `docker/metadata-action@v5` para labels/annotations | Solo metadata-action o solo manual | 4 tags + pinned tag requieren lógica custom; metadata-action complementa labels/semver |
| AD7 | Manifest validation | Shell step `docker buildx imagetools inspect` | Action de terceros o script externo | CLI directo post-push, sin dependencias extra |
| AD8 | Cache strategy | Sin cache en MVP | `type=gha` o registry cache | Imagen ~1.25GB; overhead de cache no vale la pena ahora |
| AD9 | docker-compose.yml update | Descomentar línea 17, imagen `ghcr.io/Yoppai/opencode-openchamber:latest` | Mantener solo build local | Usuarios que hacen pull desde GHCR necesitan referencia |
| AD10 | .dockerignore review | Agregar `.github/` si falta; resto suficiente | Excluir todo excepto Dockerfile | Prevenir metadata de CI en contexto de build |

## Data Flow

```
┌─────────────┐     push main / tag v* / workflow_dispatch
│   GitHub    │─────────────────────────────────────────────┐
│   Events    │                                             │
└─────────────┘                                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│  Job: build-and-publish                                             │
│  ─────────────────────                                              │
│  1. checkout                                                        │
│  2. setup-qemu-action@v3                                            │
│  3. setup-buildx-action@v3                                          │
│  4. login-action@ghcr (GITHUB_TOKEN)                                │
│  5. compute tags (latest, main, sha-xxx, pinned)                    │
│  6. build-push-action@v6 --platform linux/amd64,linux/arm64         │
│     └── Dockerfile usa TARGETARCH para elegir tarball Bun           │
│  7. imagetools inspect <image>:<tag> ──► valida amd64 + arm64      │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                          ghcr.io/Yoppai/opencode-openchamber
                          ├── :latest
                          ├── :main
                          ├── :sha-<shortsha>
                          └── :openchamber-<v>-opencode-<v>
```

## File Changes

| File | Action | Description |
|---|---|---|
| `.github/workflows/publish.yml` | Create | Workflow de build y push multi-arch a GHCR |
| `docker-compose.yml` | Modify | Descomentar línea 17, referencia a imagen GHCR |
| `.dockerignore` | Modify | Agregar `.github/` para excluir metadata CI |
| `openspec/specs/ghcr-publishing/spec.md` | Create | Spec de comportamiento del flujo (por sdd-spec) |
| `openspec/specs/container-image/spec.md` | Modify | Delta: requisitos de tags y multi-arch en build output |

## Interfaces / Contracts

**Workflow inputs (`workflow_dispatch`):**
- `OPENCHAMBER_VERSION`: string, default `latest`
- `OPENCODE_VERSION`: string, default `latest`

**Build args pasados a Dockerfile:**
- `OPENCHAMBER_VERSION` (desde input o default)
- `OPENCODE_VERSION` (desde input o default)

**Tag Matrix**

| Trigger | Tags generados |
|---|---|
| Push `main` | `latest`, `main`, `sha-<shortsha>` |
| Tag `v*` | `latest`, `sha-<shortsha>`, `openchamber-<v>-opencode-<v>` |
| `workflow_dispatch` | `latest`, `sha-<shortsha>`, `openchamber-<v>-opencode-<v>` |

*Nota:* `latest` siempre se actualiza en cualquier trigger exitoso. El tag pinned solo se genera cuando se proveen versiones explícitas o se extraen de `github.ref_name` en tag dispatch.

## Testing Strategy

| Layer | What to Test | Approach |
|---|---|---|
| Integration | Workflow ejecuta sin error | Push a branch de prueba o dry-run local con `act` |
| Integration | Manifest multi-arch válido | Paso `imagetools inspect` en CI; falla si falta plataforma |
| E2E | `docker-compose.yml` levanta desde GHCR | Pull de `:latest` en runner limpio, `docker compose up`, healthcheck pasa |

## Migration / Rollout

**Riesgos y mitigaciones:**
- **ARM build lento (30-60 min):** Aceptado para MVP. Mitigación futura: runner ARM nativo o cache.
- **Primer CI, errores de permisos GHCR:** Validar `packages: write` en `GITHUB_TOKEN` antes de merge.
- **Imagen grande, empuje lento:** Compresión gzip default del registry; no optimizar ahora.
- **Tag conflicts:** `latest` siempre overwrite; usar `sha-<shortsha>` para inmutabilidad.

**Rollback plan:**
1. Revertir merge del PR elimina `publish.yml`.
2. Imágenes ya publicadas permanecen en GHCR pero no se actualizan.
3. Para detener publicación inmediata sin revertir código: deshabilitar workflow desde UI GitHub Actions.

## Open Questions

- [ ] ¿El tag pinned debe parsear versiones desde `package.json` o solo desde inputs/tag name?
- [ ] ¿Se habilitará `type=gha` cache en fase posterior o se mantiere sin cache?
