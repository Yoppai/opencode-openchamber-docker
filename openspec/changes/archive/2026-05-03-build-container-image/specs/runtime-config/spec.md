# runtime-config Specification

## Purpose
Define comportamiento observable del entorno runtime dentro del contenedor.

## Requirements

### Requirement: Usuario no-root
El contenedor MUST ejecutar procesos principales con usuario `openchamber` de UID/GID 1000.

#### Scenario: Identidad de usuario runtime

- GIVEN un contenedor corriendo
- WHEN se consulta el usuario efectivo del proceso
- THEN es `openchamber` con UID 1000 y GID 1000

### Requirement: Entorno limpio sin responsabilidades de ch-03
El runtime de ch-02 MUST NOT incluir lógica de entrypoint para mapeo de password ni seed/merge de plugin `opencode-synced`.

#### Scenario: Ausencia de lógica ch-03 en imagen ch-02

- GIVEN una imagen construida bajo ch-02
- WHEN se inspecciona el entrypoint o scripts de arranque
- THEN no existe código que lea `UI_PASSWORD` ni modifique `opencode.json`/`opencode.jsonc`
