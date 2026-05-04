# Tasks: Publish GHCR Multi-Arch

## Phase 1: Foundation

- [x] 1.1 Update `.dockerignore` — add `.github/` to exclude CI metadata from build context.
- [x] 1.2 Verify `Dockerfile` declares `ARG OPENCODE_VERSION` and `ARG OPENCHAMBER_VERSION` before and after `FROM` for build-arg propagation.

## Phase 2: Core Implementation — GHCR Workflow

- [x] 2.1 Create `.github/workflows/publish.yml` with triggers: `push` to `main`, `push` tags `v*`, `workflow_dispatch`.
- [x] 2.2 Add `workflow_dispatch` inputs `OPENCHAMBER_VERSION` (default `latest`) and `OPENCODE_VERSION` (default `latest`).
- [x] 2.3 Add QEMU setup step (`docker/setup-qemu-action@v3`) for cross-platform emulation.
- [x] 2.4 Add Buildx setup step (`docker/setup-buildx-action@v3`) with default driver.
- [x] 2.5 Add GHCR login step (`docker/login-action@v3`) using `GITHUB_TOKEN` with `registry: ghcr.io`.
- [x] 2.6 Add build+push step (`docker/build-push-action@v6`) with `platforms: linux/amd64,linux/arm64` and build args passed from workflow inputs/defaults.
- [x] 2.7 Compute tags: `latest`, `main` (on main push), `sha-<shortsha>` (always), and `openchamber-<v>-opencode-<v>` (always, defaults to `latest`).
- [x] 2.8 Add manifest validation step that runs `docker buildx imagetools inspect` and fails if `linux/amd64` or `linux/arm64` is missing.

## Phase 3: Integration

- [x] 3.1 Update `docker-compose.yml` — uncomment line 17 and set `image: ghcr.io/Yoppai/opencode-openchamber:latest`.
- [x] 3.2 Add comment in `docker-compose.yml` noting that `build:` block remains as local fallback.

## Phase 4: Verification

- [x] 4.1 Verify workflow triggers match spec: push to `main`, push tag `v*`, and `workflow_dispatch`.
- [x] 4.2 Verify `GITHUB_TOKEN` has `packages: write` permission in workflow `permissions` block.
- [x] 4.3 Verify manifest validation step asserts both `linux/amd64` and `linux/arm64` platforms are present.
- [x] 4.4 Verify `docker-compose.yml` can pull and run from GHCR (`docker compose up` uses image reference).
