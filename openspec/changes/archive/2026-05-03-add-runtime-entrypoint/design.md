# Design: add-runtime-entrypoint

## Technical Approach

Bash entrypoint script executed by `tini` on container start. It seeds/merges `opencode.jsonc`, resolves password flags, and `exec`s `openchamber serve --foreground` so the process remains under tini’s PID 1 subtree.

## Architecture Decisions

### Decision: Entrypoint Language & Strictness

| Choice | Rationale |
|--------|-----------|
| `bash` with `set -euo pipefail` | Fail fast on errors, undefined variables, and pipeline failures. Matches proposal requirement for robust container bootstrap. |

### Decision: Password Mapping & Fallback

| Choice | Rationale |
|--------|-----------|
| Map `UI_PASSWORD` → `--ui-password` flag; rely on `OPENCHAMBER_UI_PASSWORD` upstream env fallback; warn if both empty | Keeps priority clear: explicit flag overrides env. Warning satisfies PRD §240-246 without blocking startup. |

### Decision: Seed/Merge Algorithm

| Choice | Rationale |
|--------|-----------|
| `jq` for idempotent plugin append; backup before mutate | `jq` is declarative and handles JSON/JSONC field manipulation safely. Backup prevents data loss on malformed input. |

**Pseudocode:**
```bash
CONFIG="$HOME/.config/opencode/opencode.jsonc"
if [ ! -f "$CONFIG" ]; then
  mkdir -p "$(dirname "$CONFIG")"
  echo '{"$schema":"https://opencode.ai/config.json","plugin":["opencode-synced"]}' > "$CONFIG"
else
  cp "$CONFIG" "$CONFIG.bak.$$"
  jq 'if has("plugin") then (if (.plugin|index("opencode-synced")) then . else .plugin+=["opencode-synced"] end) else .+{"plugin":["opencode-synced"]} end' "$CONFIG.bak.$$" > "$CONFIG" || { mv "$CONFIG.bak.$$" "$CONFIG"; exit 1; }
  rm -f "$CONFIG.bak.$$"
fi
```

### Decision: Variable Forwarding

All runtime variables from PRD §424-480 pass through transparently (Docker inherits env by default). Explicitly documented set:

- `UI_PASSWORD`, `OPENCHAMBER_UI_PASSWORD`, `GH_TOKEN`
- `OPENCHAMBER_HOST`, `OPENCHAMBER_PORT`, `OPENCHAMBER_DATA_DIR`
- `OPENCHAMBER_OPENCODE_HOSTNAME`
- `OPENCODE_HOST`, `OPENCODE_PORT`, `OPENCODE_SKIP_START`
- `OPENCHAMBER_TUNNEL_PROVIDER`, `OPENCHAMBER_TUNNEL_MODE`, `OPENCHAMBER_TUNNEL_HOSTNAME`, `OPENCHAMBER_TUNNEL_TOKEN`, `OPENCHAMBER_TUNNEL_CONFIG`
- `OH_MY_OPENCODE`

Build-time args (`OPENCHAMBER_VERSION`, `OPENCODE_VERSION`) are not forwarded; they are baked into the image.

### Decision: Dockerfile Integration

| Change | Detail |
|--------|--------|
| Install `jq` | Add to `apt-get install` list. |
| COPY `entrypoint.sh` | Copy to `/usr/local/bin/entrypoint.sh` and `chmod +x` **before** `USER openchamber`. |
| Override ENTRYPOINT | `ENTRYPOINT ["tini", "--", "/usr/local/bin/entrypoint.sh"]`; `CMD []`. |

## Data Flow

### Normal Flow

```
[Container start] → tini → entrypoint.sh → seed/merge config
                                          ↓
                    build args ← password check ← UI_PASSWORD set
                                          ↓
                              exec openchamber serve --foreground ...
```

### No Password Flow

```
[Container start] → tini → entrypoint.sh → seed/merge config
                                          ↓
                    warning to stderr ← both passwords empty
                                          ↓
                              exec openchamber serve --foreground ...
```

### Existing Config Flow

```
[Container start] → tini → entrypoint.sh → opencode.jsonc exists
                                          ↓
                         jq merge (backup first) → preserves all fields
                                          ↓
                              exec openchamber serve --foreground ...
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `entrypoint.sh` | Create | Bash entrypoint with seed/merge, password mapping, and `exec openchamber serve`. |
| `Dockerfile` | Modify | Add `jq`; copy & chmod `entrypoint.sh`; update `ENTRYPOINT`/`CMD`. |

## Interfaces / Contracts

- **Input**: Environment variables listed above + `$HOME` layout.
- **Output**: Mutated `~/.config/opencode/opencode.jsonc` (idempotent) + `exec` replacement to `openchamber serve --foreground`.
- **Ownership**: Script runs as `openchamber` (UID 1000). File writes target paths under `$HOME`, owned by UID 1000 or host-mapped volumes with matching UID.

## Testing Strategy

| Layer | What to Test | Approach |
|-------|--------------|----------|
| Unit | `entrypoint.sh` logic | ShellCheck static analysis; bats-core for seed/merge and password branches. |
| Integration | Container start | `docker run` with/without `UI_PASSWORD`; assert logs contain warning or `--ui-password` in process list. |
| E2E | Idempotent merge | Run twice with same volume; assert `opencode-synced` appears exactly once and user fields persist. |

## Migration / Rollout

No migration required. New image tag includes entrypoint; existing Compose files only need to ensure `UI_PASSWORD` is set for cloud deployments.

## Risks / Mitigations

| Risk | Mitigation |
|------|------------|
| `jq` missing in image | Add `jq` to `apt-get install` in Dockerfile. |
| `opencode.jsonc` malformed | Backup before `jq` mutation; restore and exit non-zero on failure so container crash-loops visibly instead of corrupting config. |
| Permission denied on config write | `entrypoint.sh` runs as UID 1000. Ensure host volumes map UID 1000; script creates directories with `mkdir -p` under `$HOME`, which is owned by openchamber. |

## Open Questions

- None.
