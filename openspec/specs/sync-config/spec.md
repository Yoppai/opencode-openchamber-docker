# sync-config Specification

## Purpose

Definir comportamiento observable del seed y merge del plugin `opencode-synced` en la configuración de OpenCode al arrancar el contenedor.

## Requirements

### Requirement: Crear configuración base si no existe

El entrypoint MUST crear `opencode.jsonc` con configuración base cuando no existe `opencode.json` ni `opencode.jsonc` en el directorio de configuración.

#### Scenario: Config ausente al arrancar

- GIVEN que no existe `opencode.json` ni `opencode.jsonc`
- WHEN el entrypoint ejecuta la lógica de seed
- THEN crea `opencode.jsonc` con contenido base que incluye `plugin: ["opencode-synced"]`

### Requirement: Agregar plugin sin destruir configuración existente

El entrypoint MUST agregar `opencode-synced` al arreglo `plugin` de la configuración existente sin borrar ni modificar otros campos.

#### Scenario: Config existente sin opencode-synced

- GIVEN que existe `opencode.jsonc` con campos definidos por el usuario
- WHEN el entrypoint ejecuta el merge
- THEN `opencode-synced` se agrega al arreglo `plugin`
- AND todos los demás campos permanecen intactos

### Requirement: Evitar duplicación de plugin

El entrypoint MUST NOT agregar `opencode-synced` si ya existe en el arreglo `plugin`.

#### Scenario: Config existente con opencode-synced ya presente

- GIVEN que `opencode.jsonc` ya contiene `opencode-synced` en `plugin[]`
- WHEN el entrypoint ejecuta el merge
- THEN `opencode-synced` aparece exactamente una vez en `plugin[]`
- AND ningún otro campo se modifica

### Requirement: Operación segura sobre JSONC y JSON

El entrypoint SHOULD usar herramientas que operen de forma segura sobre archivos JSONC o JSON sin corromper comentarios ni estructura cuando sea posible.

#### Scenario: Config JSONC con comentarios se preserva

- GIVEN que `opencode.jsonc` contiene comentarios válidos
- WHEN el entrypoint modifica el arreglo `plugin`
- THEN los comentarios y la estructura del archivo se preservan
