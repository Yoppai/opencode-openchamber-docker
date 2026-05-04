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

### Requirement: REQ-DOC-SYNC-FLOW Documentar flujo de sincronización

La documentación de usuario MUST explicar el flujo `/sync-init` (máquina local) seguido de `/sync-link <repo>` (VPS).

#### Scenario: Usuario sigue el flujo de sincronización con éxito

- DADO que el usuario tiene OpenCode en su máquina local y OpenChamber corriendo en VPS
- CUANDO el usuario ejecuta `/sync-init` localmente y luego `/sync-link <repo>` en el VPS
- ENTONCES la documentación guía paso a paso cada comando
- AND el usuario obtiene la configuración local replicada en el VPS

#### Scenario: Documentación advierte sobre sobrescritura de configuración

- DADO que el VPS ya tiene configuración existente
- CUANDO el usuario consulta la documentación antes de ejecutar `/sync-link`
- ENTONCES la documentación MUST mostrar una advertencia visible de que `/sync-link` puede sobrescribir la configuración local del VPS

### Requirement: REQ-DOC-SYNC-SCOPE Documentar alcance de sincronización

La documentación MUST listar explícitamente qué elementos sincroniza `opencode-synced` y qué elementos excluye por default.

#### Scenario: Tabla clara de elementos sincronizados vs excluidos

- DADO que el usuario lee la documentación de sincronización
- CUANDO busca entender qué se replica entre máquinas
- ENTONCES la documentación presenta una tabla o lista que contrasta elementos sincronizados contra no sincronizados

#### Scenario: Documentación menciona elementos en alcance positivo

- DADO que el usuario revisa la sección de alcance
- CUANDO lee la lista de elementos sincronizados
- ENTONCES la documentación menciona explícitamente: configuración (`opencode.json`/`opencode.jsonc`), plugins, skills, agents y temas

#### Scenario: Documentación excluye explícitamente elementos sensibles

- DADO que el usuario revisa la sección de exclusiones
- CUANDO lee qué no se sincroniza por default
- ENTONCES la documentación lista explícitamente: secrets, sesiones, prompt stash y stores sensibles de plugins multi-auth

### Requirement: REQ-DOC-SYNC-SECURITY Incluir guía de seguridad

La documentación MUST incluir advertencias de seguridad relacionadas con la sincronización de configuración.

#### Scenario: Documentación advierte default de secrets

- DADO que el usuario lee la sección de seguridad
- CUANDO consulta si sus secrets se sincronizan
- ENTONCES la documentación advierte que `includeSecrets` es `false` por default y explica por qué

#### Scenario: Documentación recomienda repo privado

- DADO que el usuario configura el repositorio de sincronización
- CUANDO lee las recomendaciones de seguridad
- ENTONCES la documentación SHOULD recomendar usar un repositorio privado para el sync

#### Scenario: Documentación advierte sobre stores multi-auth

- DADO que el usuario tiene plugins de autenticación configurados
- CUANDO lee sobre sincronización de stores sensibles
- ENTONCES la documentación advierte que los stores multi-auth contienen tokens OAuth y no deben sincronizarse por default
- AND la documentación menciona que `extraSecretPaths` es opt-in avanzado para casos excepcionales

#### Scenario: Documentación explica conflictos de sesiones

- DADO que el usuario considera sincronizar sesiones entre múltiples máquinas
- CUANDO lee las advertencias de sincronización
- ENTONCES la documentación explica que las sesiones pueden generar conflictos en Git
- AND la documentación recomienda usar Turso como backend de sesiones para multi-máquina

### Requirement: REQ-DOC-VOLUME-VS-SYNC Distinguir volumen de sincronización Git

La documentación MUST explicar la diferencia entre persistencia local mediante volúmenes Docker y replicación cross-machine mediante Git sync.

#### Scenario: Usuario entiende la diferencia entre volumen y Git sync

- DADO que el usuario despliega OpenChamber en VPS
- CUANDO lee la sección de persistencia y sincronización
- ENTONCES entiende que los volúmenes host preservan datos localmente en el VPS ante recreaciones del contenedor
- AND entiende que `opencode-synced` replica configuración entre máquinas distintas mediante Git

> **Note**: Esta distinción evita que el usuario confunda persistencia local con replicación remota.
