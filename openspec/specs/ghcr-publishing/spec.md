# ghcr-publishing Specification

## Purpose
Define comportamiento del flujo de CI/CD que publica imagen Docker multi-arch en GHCR.

## Requirements

### Requirement: CI Trigger → GHCR Publish
El sistema MUST publicar imagen multi-arch en `ghcr.io/Yoppai/opencode-openchamber` ante triggers definidos.

#### Scenario: Push a main publica imagen
- DADO un push a la rama `main`
- CUANDO el workflow de CI ejecuta
- ENTONCES publica imagen multi-arch en GHCR

#### Scenario: Workflow dispatch con overrides de version
- DADO un trigger `workflow_dispatch` con inputs `OPENCHAMBER_VERSION` y `OPENCODE_VERSION`
- CUANDO el workflow de CI ejecuta
- ENTONCES usa los valores de version proporcionados en el dispatch para el build

#### Scenario: Push de tag semver publica con tag de version
- DADO un push de tag que coincide con `v*`
- CUANDO el workflow de CI ejecuta
- ENTONCES publica imagen con tag semantico derivado del tag

### Requirement: Multi-Arch Manifest
El sistema MUST garantizar que la imagen publicada contenga manifest multi-arch.

#### Scenario: Manifest contiene amd64 y arm64
- DADO una imagen publicada en GHCR
- CUANDO se inspecciona con `docker buildx imagetools inspect`
- ENTONCES el manifest contiene las plataformas `linux/amd64` y `linux/arm64`

### Requirement: Tags Convention
El sistema MUST aplicar convencion de tags segun el trigger.

#### Scenario: Push a main genera tags estandar
- DADO un push a `main`
- CUANDO el workflow publica la imagen
- ENTONCES existen los tags: `latest`, `main`, `sha-<shortsha>`, `openchamber-<version>-opencode-<version>`

#### Scenario: Workflow dispatch usa versiones del dispatch en tag pinned
- DADO un `workflow_dispatch` con overrides de `OPENCHAMBER_VERSION` y `OPENCODE_VERSION`
- CUANDO el workflow publica la imagen
- ENTONCES el tag `openchamber-<version>-opencode-<version>` usa las versiones del dispatch

#### Scenario: Valores default generan tag pinned con latest
- DADO un push a `main` sin overrides explicitos
- CUANDO el workflow publica la imagen
- ENTONCES el tag `openchamber-<version>-opencode-<version>` usa `latest` como version default resuelta en build time

### Requirement: Build Args Propagation
El sistema MUST propagar build args desde el workflow hacia el Dockerfile.

#### Scenario: Build args se pasan correctamente en CI
- DADO un Dockerfile con ARG `OPENCHAMBER_VERSION` y `OPENCODE_VERSION`
- CUANDO el job de build+push ejecuta en CI
- ENTONCES los build args se pasan correctamente desde el trigger al comando de build

### Requirement: GHCR Authentication
El sistema MUST autenticar con GHCR usando el token del workflow.

#### Scenario: Push a GHCR con GITHUB_TOKEN
- DADO un workflow ejecutandose en el repositorio
- CUANDO realiza push a GHCR
- ENTONCES se autentica con `GITHUB_TOKEN` con scope `packages: write`
