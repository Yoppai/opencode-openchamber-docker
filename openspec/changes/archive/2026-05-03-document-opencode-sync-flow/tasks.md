# Tasks: Documentar Flujo opencode-synced

## Phase 1: Fix stale registry README

- [x] 1.1 Update `openspec/specs/sync-config/README.md`
  - Replace stale line "no `spec.md` yet" with link to existing `spec.md`
  - Acceptance: file references `spec.md` and no stale status text remains

## Phase 2: Core documentation

- [x] 2.1 Create `docs/sync-flow.md`
  - Sections: Overview, Prerequisites, Flujo local (`/sync-init`), Flujo VPS (`/sync-link <repo>`), Tabla sync/no-sync, Seguridad, Volumen vs Git sync, Sesiones multi-máquina (Turso), Troubleshooting
  - Acceptance: all sections present; REQ-DOC-SYNC-FLOW, REQ-DOC-SYNC-SCOPE, REQ-DOC-SYNC-SECURITY, REQ-DOC-VOLUME-VS-SYNC scenarios covered

- [x] 2.2 Create root `README.md`
  - Quick reference para sync; badge/link a `docs/sync-flow.md`; link a specs y quickstart
  - Acceptance: README exists, links to `docs/sync-flow.md`, references REQ-DOC-QUICKSTART-SYNC scenario (sección sync tras bootstrap)

## Phase 3: Verification

- [x] 3.1 Cross-check scenarios against specs
  - For each spec scenario in `specs/sync-config/spec.md` and `specs/vps-quickstart/spec.md`, confirm coverage in `docs/sync-flow.md` or `README.md`
  - Acceptance: checklist of all scenarios mapped to doc section/line

- [x] 3.2 Validate Markdown and links
  - Run `markdownlint` on new files; verify all relative paths resolve
  - Acceptance: zero lint errors; `docs/sync-flow.md` → `openspec/specs/sync-config/spec.md` and `openspec/specs/vps-quickstart/spec.md` links valid
