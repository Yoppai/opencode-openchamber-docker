# Archive Report: publish-ghcr-multiarch

**Archived**: 2026-05-04  
**Archive path**: `openspec/changes/archive/2026-05-04-publish-ghcr-multiarch/`

---

## What Was Completed

Implementación completa de CI/CD para publicar imagen Docker multi-arch (`linux/amd64`, `linux/arm64`) a GHCR. Incluye:

- Workflow `.github/workflows/publish.yml` con triggers: push a `main`, tags `v*`, `workflow_dispatch`
- QEMU + Buildx para build cross-platform
- Tags: `latest`, `main`, `sha-<shortsha>`, `openchamber-<v>-opencode-<v>`
- Manifest validation post-push con `docker buildx imagetools inspect`
- `docker-compose.yml` referencia a imagen GHCR activada
- `.dockerignore` actualizado para excluir `.github/`

## Delta Specs Synced

| Domain | Action | Details |
|--------|--------|---------|
| `ghcr-publishing` | Created | NEW spec — 6 requirements, 12 scenarios covering triggers, multi-arch manifest, tags convention, build args propagation, GHCR auth |
| `container-image` | Updated | MODIFIED "Build arguments para versiones" (expanded to CI context + new scenario); ADDED "CI Reproducibility" requirement (1 scenario) |

## Verification Result

**PASS** — 16/16 tasks complete, 11/12 scenarios compliant, 1 partial (manifest remote 403 pre-publication). Zero CRITICAL issues.

## Files Created/Modified

| File | Action |
|------|--------|
| `.github/workflows/publish.yml` | Created |
| `docker-compose.yml` | Modified (line 17 uncommented) |
| `.dockerignore` | Modified (added `.github/`) |
| `openspec/specs/ghcr-publishing/spec.md` | Created |
| `openspec/specs/container-image/spec.md` | Updated (delta merge) |
| `openspec/ROADMAP.md` | Updated (ch-06 archivado, v1.2) |

## ROADMAP Updates

- **v1.2**: Changelog entry added
- **Completados**: ch-06 row added
- **Fase 3**: Status changed ✅ Archivado, specs 🟢 Especificado
- **Acceptance Criteria**: All 3 ch-06 criteria marked [x]
- **Gaps**: #4 (multi-arch ARM CI) and #7 (GHCR owner/tag policy) marked 🟢 Resuelto
- **Próximo paso**: Updated to ch-07
- **Spec status**: `ghcr-publishing` 🟡 Registrado → 🟢 Especificado

## Archive Contents

- proposal.md ✅
- specs/ghcr-publishing/spec.md ✅ (copy, source now at main specs)
- specs/container-image/spec.md ✅ (delta, merged into main specs)
- design.md ✅
- tasks.md ✅ (16/16 tasks complete)
- verify-report.md ✅ (PASS)
- archive-report.md ✅ (this file)
