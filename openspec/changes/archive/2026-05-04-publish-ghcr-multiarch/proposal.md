# Proposal: Publish GHCR Multi-Arch

## Intent

Automatizar publicación de imagen Docker multi-arch (linux/amd64, linux/arm64) a GHCR en cada push a main, tag v*, o workflow_dispatch.

## Scope

### In Scope
- Crear `.github/workflows/publish.yml` con QEMU, Buildx, GHCR login, build+push multi-arch.
- Generar tags: `latest`, `main`, `sha-<shortsha>`, `openchamber-<v>-opencode-<v>`.
- Validar manifest multi-arch post-push con `docker buildx imagetools inspect`.
- Activar referencia GHCR en `docker-compose.yml`.
- Crear spec `ghcr-publishing` y delta spec `container-image`.

### Out of Scope
- Auto-merge, PR checks adicionales, Dependabot/Renovate (ch-07).
- Optimización de tamaño de imagen o multi-stage build.
- Pruebas de rendimiento ARM64.

## Capabilities

### New Capabilities
- `ghcr-publishing`: flujo de CI/CD para publicar imagen multi-arch en GHCR con tags versionados y validación de manifest.

### Modified Capabilities
- `container-image`: agregar requisitos de tags y multi-arch como contrato de salida de build (delta spec).

## Approach

Usar GitHub Actions nativos: `docker/setup-qemu-action`, `docker/setup-buildx-action`, `docker/login-action` para GHCR. Job único que construye y empuja ambas plataformas en paralelo. Extraer versiones desde `github.ref_name` o inputs de `workflow_dispatch`. Post-push, job de validación ejecuta `docker buildx imagetools inspect` para verificar ambas arquitecturas están presentes.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `.github/workflows/publish.yml` | New | Workflow de CI completo |
| `docker-compose.yml` | Modified | Referencia a imagen GHCR activada |
| `openspec/specs/ghcr-publishing/spec.md` | New | Spec de comportamiento |
| `openspec/specs/container-image/spec.md` | Modified | Delta spec tags/multi-arch |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Build ARM64 lento con QEMU (30-60min) | Med | Cache de buildx (`type=gha`), considerar runner ARM nativo futuro |
| Imagen grande (1.25GB) empuje lento | Med | Compresión gzip default de registry, no optimizar ahora |
| Primer CI del repo, posibles errores de permisos GHCR | Med | Validar `GITHUB_TOKEN` con permisos `packages:write` pre-merge |

## Rollback Plan

Deshacer merge del PR elimina `publish.yml`. Imágenes ya publicadas en GHCR permanecen pero no se actualizan. Para detener publicación inmediata sin revertir código, deshabilitar workflow desde UI de GitHub Actions.

## Dependencies

- `ch-02` (build-container-image) MUST estar archivado: imagen base debe existir y soportar `TARGETARCH`.
- `ch-03` (add-runtime-entrypoint) RECOMMENDED antes de release: entrypoint estable evita publicar imagen rota.

## Success Criteria

- [ ] Push a `main` publica imagen en `ghcr.io/Yoppai/opencode-openchamber`.
- [ ] `docker buildx imagetools inspect` muestra `linux/amd64` y `linux/arm64`.
- [ ] Tag pinned `openchamber-<version>-opencode-<version>` existe tras workflow_dispatch.
- [ ] `docker-compose.yml` puede levantar contenedor desde imagen GHCR.
