# Delta for container-image

Referencia: `openspec/specs/container-image/spec.md`

## ADDED Requirements

### Requirement: CI Reproducibility
La imagen MUST producir una build funcionalmente equivalente cuando se construye en CI con los mismos build args que en local.

#### Scenario: Build local y CI son equivalentes
- DADO un Dockerfile existente
- CUANDO se construye en CI con build args especificos
- ENTONCES la imagen resultante es funcionalmente equivalente a una build local con los mismos build args

## MODIFIED Requirements

### Requirement: Build arguments para versiones
La imagen MUST aceptar build args `OPENCODE_VERSION` y `OPENCHAMBER_VERSION` tanto en builds locales como en builds de CI.

(Previously: La imagen MUST aceptar build args `OPENCODE_VERSION` y `OPENCHAMBER_VERSION`.)

#### Scenario: Build con versiones explicitas
- DADO un build de imagen
- CUANDO se pasan `--build-arg OPENCODE_VERSION=1.0.0 --build-arg OPENCHAMBER_VERSION=1.9.10`
- ENTONCES la imagen resultante contiene esas versiones instaladas

#### Scenario: Build en CI con versiones explicitas
- DADO un workflow de CI que ejecuta build de imagen
- CUANDO se pasan build args `OPENCODE_VERSION` y `OPENCHAMBER_VERSION` desde el workflow
- ENTONCES la imagen resultante contiene esas versiones instaladas
