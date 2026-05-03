# Archive Report — spike-openchamber-npm-runtime

**Archived**: 2026-05-03
**Change**: spike-openchamber-npm-runtime
**Status**: PASS FOR ch-01 SPIKE / NO-GO FOR ch-02
**Artifact Store**: hybrid
**Archiver**: sdd-archive (ch-01 archive, no commit)

## Engram Observation IDs

| Artifact | Engram ID |
|----------|-----------|
| proposal | #718 |
| spec (delta) | #719 |
| design | #720 |
| tasks | #721 |
| apply-progress | #722 |
| verify-report | #725 |

## Archive Path

```
openspec/changes/archive/2026-05-03-spike-openchamber-npm-runtime/
```

## Spec Sync Decision

**SKIPPED** — Delta spec domain `runtime-validation` is validation-only spike artifact:

| Requirement | Status | Sync decision |
|-------------|--------|---------------|
| R1: Binary exposure | ✅ PASSED | Would be safe to sync, but entire domain is validation-only |
| R2: Server startup | ❌ BLOCKED (opencode missing) | NOT behaviorally true — would overstate capability |
| R3: Password auth | ❌ BLOCKED (serve blocked) | NOT behaviorally true — would overstate capability |
| R4: ARM64 native deps | ✅ PASSED | Documented in decisions.md |
| R5: Decision document | ✅ COMPLIANT (NO-GO) | Documented in decisions.md |

Per project standards:
- "Do not convert failed password/serve without opencode into product guarantees"
- "If delta spec is validation-only, archive without overstating product capability"
- "Archive ch-01 as validation/discovery, not as a guarantee that production image exists"

## ROADMAP Updates

- Changelog v0.6: ch-01 archived
- Completados: ch-01 added
- Fase 1 table: ch-01 marked ✅ Archivado (NO-GO ch-02)
- Fase 1 acceptance criteria: updated to reflect spike discovery
- Estado de Specs: runtime-validation added as validation-only
- Notas técnicas Fase 1: ch-01 findings documented

## Key Findings Preserved

1. `openchamber serve` REQUIRES `opencode` CLI on PATH — only `--version` works without it
2. Prebuilds for `better-sqlite3`, `node-pty`, `bun-pty` work on AMD64 and ARM64 (no node-gyp)
3. ARM64 via QEMU functional but ~4x slower (QEMU overhead, not compilation)
4. ch-02 is NO-GO until opencode dependency is resolved

## Artifact Inventory

| Artifact | Present |
|----------|---------|
| proposal.md | ✅ |
| exploration.md | ✅ |
| specs/runtime-validation/spec.md (delta) | ✅ |
| design.md | ✅ |
| tasks.md | ✅ (8/8 complete) |
| verify-report.md | ✅ (PASS spike / NO-GO ch-02) |
| scripts/ | ✅ (5 validation scripts) |
| evidence/ | ✅ (12 evidence files) |
| decisions.md | ✅ |

## Next Recommended

`ch-02 build-container-image` — resolve opencode dependency (install `opencode-ai` CLI or set `OPENCODE_BINARY`), then build production Dockerfile.
