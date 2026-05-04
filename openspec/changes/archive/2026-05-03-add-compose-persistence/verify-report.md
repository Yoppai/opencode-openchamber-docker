# Verification Report: add-compose-persistence (ch-04) — Third/final verification

**status**: complete  
**mode**: Standard Verify (`strict_tdd: false`; no test runner)  
**executive_summary**: Final v3: CRITICAL 0, WARNING 1, SUGGESTION 0  
**verdict**: PASS_WITH_WARNINGS

## Focus Finding

### SSH permissions ordering bug

**Result**: ✅ Fixed.

Evidence:

- `scripts/init-dirs.sh:54` applies broad fallback `chmod -R 755 data/ workspaces/`.
- `scripts/init-dirs.sh:56-63` applies SSH strict permissions after fallback:
  - `chmod 700 data/ssh`
  - `chmod 600 data/ssh/*` when files exist
- Runtime execution in Linux container confirms final state after intentionally bad permissions:
  - `data/ssh` → `700`
  - `data/ssh/id_rsa` → `600`

This satisfies `persistence` requirement “Permisos SSH estrictos”: SSH dir MUST be `700`; private key files MUST be `600`.

## Quick Check Results

| Check | Result | Evidence |
|---|---|---|
| `init-dirs.sh` chmod order | ✅ PASS | broad `755` at line 54; SSH `700/600` at lines 57/62 after it |
| `init-dirs.sh` runtime permission scenario | ✅ PASS | `docker run ... bash scripts/init-dirs.sh` produced `ssh_dir=700`, `ssh_key=600`, `dirs_ok` |
| `entrypoint.sh` LF | ✅ PASS | `git ls-files --eol` shows `entrypoint.sh` as `i/lf w/lf attr/text eol=lf` |
| `entrypoint.sh` writability guard | ✅ PASS | `entrypoint.sh:16-22` creates/checks writable `CONFIG_DIR` before config writes |
| `entrypoint.sh` SSH defense | ✅ PASS | `entrypoint.sh:63-66` applies `chmod 700` dir + `chmod 600` files |
| `docker-compose.yml` previous fixes | ✅ PASS | 10 bind mounts, `user: "1000:1000"`, env file, healthcheck, `restart: unless-stopped` intact |
| `.env.example` vars | ✅ PASS | 17 runtime vars; `OPENCHAMBER_CONFIG_DIR` and `OPENCHAMBER_DATA_DIR` present |
| `.gitattributes` | ✅ PASS | present with `*.sh text eol=lf` and `Dockerfile text eol=lf` |
| Compose syntax | ✅ PASS | `docker compose config` resolved successfully |
| Shell syntax | ✅ PASS | Linux container `bash -n /src/scripts/init-dirs.sh && bash -n /src/entrypoint.sh` passed |

## Completeness

| Metric | Value |
|---|---:|
| Tasks total | 11 |
| Tasks marked complete `[x]` | 6 |
| Tasks marked incomplete `[ ]` | 5 |

Incomplete tasks: Phase 4 tasks 4.1–4.5 remain unchecked in `tasks.md`.

## Build & Tests Execution

**Build / config**: ✅ Passed

```text
docker compose config
Result: exit code 0; compose config resolved successfully.
```

**Script syntax**: ✅ Passed

```text
docker run --rm -v E:\Projects\opencode-openchamber-docker:/src:ro bash:5.2 bash -lc "bash -n /src/scripts/init-dirs.sh && bash -n /src/entrypoint.sh"
Result: exit code 0; no output.
```

**Behavioral permission test**: ✅ Passed

```text
docker run --rm -v E:\Projects\opencode-openchamber-docker:/src:ro bash:5.2 bash -lc '... bash scripts/init-dirs.sh ... stat ...'
ssh_dir=700
ssh_key=600
dirs_ok
```

**Project test runner**: ➖ Not available (`openspec/config.yaml` declares `test_runner.command: null`).

**Coverage**: ➖ Not available.

## Spec Compliance Matrix

| Requirement | Scenario | Test / Evidence | Result |
|---|---|---|---|
| persistence: Matriz de volúmenes completa | Todos los volúmenes montados y datos sobreviven recreación | Static compose check: 10 bind mounts present; `docker compose config` passes | ✅ COMPLIANT static |
| persistence: Permisos SSH estrictos | init script corrige permisos SSH existentes | Linux container execution: bad `777` dir/key corrected to `700/600` | ✅ COMPLIANT |
| persistence: Inicialización de directorios | Fresh clone con directorios ausentes | Linux container execution validated all 10 dirs exist | ✅ COMPLIANT |
| persistence: Ownership correcto para usuario no-root | Container puede escribir en volúmenes inicializados | Compose has `user: "1000:1000"`; init fallback `755`; runtime container write not executed | ⚠️ PARTIAL |
| runtime-config: Corrección defensiva de permisos | SSH mount con permisos incorrectos | `entrypoint.sh:63-66` chmods dir/files before launching server | ✅ COMPLIANT static |

**Compliance summary**: 4/5 checked scenarios compliant; 1 partial due full service runtime not executed in this final focused pass.

## Correctness (Static — Structural Evidence)

| Requirement | Status | Notes |
|---|---|---|
| SSH init permissions | ✅ Implemented | Final order preserves `data/ssh=700` and keys `600` |
| Init dirs creates 10 paths | ✅ Implemented | All expected `mkdir -p` paths present |
| Entrypoint writability guard | ✅ Implemented | Config dir checked before write |
| Entrypoint SSH defense | ✅ Implemented | Dir + files protected |
| Compose persistence mounts | ✅ Implemented | 10 bind mounts present |
| Env template | ✅ Implemented | 17 runtime vars, config/data dirs present |
| Git LF guard | ✅ Implemented | `.gitattributes` present; shell scripts LF in worktree |

## Coherence (Design)

| Decision | Followed? | Notes |
|---|---|---|
| AD-1 Compose v2 with `build: .` | ✅ Yes | `build.context: .` |
| AD-2 Single service | ✅ Yes | one service: `openchamber` |
| AD-3 Relative bind mounts | ✅ Yes | `./data/*`, `./workspaces` |
| AD-4 Healthcheck curl root | ✅ Yes | curl root without `-f`; any HTTP response accepted |
| AD-5 `.env.example` documented | ✅ Yes | 17 runtime vars and build-arg note |
| AD-6 `scripts/init-dirs.sh` | ✅ Yes | script in `scripts/`; SSH strict chmod final |

## Issues Found

**CRITICAL** (must fix before archive):

- None.

**WARNING** (should fix):

- Phase 4 tasks 4.1–4.5 remain unchecked in `tasks.md`. This is process/documentation status, not remaining SSH code defect. Final focused verification executed init permission scenario and compose config; full `docker compose up/down` runtime validation remains unmarked.

**SUGGESTION** (nice to have):

- None.

## Verdict

**PASS_WITH_WARNINGS** — SSH permissions ordering bug fixed. No blocking code/spec issue remains for checked scope; archive can proceed if Phase 4 checkbox warning is accepted or updated by orchestrator.

**skill_resolution**: none — no Project Standards block; phase skill + shared SDD/OpenSpec conventions loaded directly.
