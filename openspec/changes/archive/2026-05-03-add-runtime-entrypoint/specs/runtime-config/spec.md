# Delta for runtime-config

## MODIFIED Requirements

### Requirement: Entorno limpio sin responsabilidades de ch-03

El runtime de ch-02 MUST NOT incluir lógica de entrypoint para mapeo de password ni seed/merge de plugin `opencode-synced`.
(Previously: Este requisito excluía explícitamente lógica de entrypoint porque ch-03 no estaba implementado.)

#### Scenario: Ausencia de lógica ch-03 en imagen ch-02

- GIVEN una imagen construida bajo ch-02
- WHEN se inspecciona el entrypoint o scripts de arranque
- THEN no existe código que lea `UI_PASSWORD` ni modifique `opencode.json`/`opencode.jsonc`

### Requirement: Entrypoint como punto de arranque del contenedor

El contenedor MUST ejecutar un entrypoint script al iniciar. Este script MUST leer variables de entorno runtime, preparar la configuración de OpenCode, y lanzar OpenChamber con los flags correctos.

#### Scenario: Entrypoint ejecutado por tini como PID 1

- GIVEN un contenedor iniciado
- WHEN se inspecciona el proceso con PID 1
- THEN el PID 1 es `tini` y su hijo directo es el entrypoint script

#### Scenario: UI_PASSWORD presente se mapea a flag

- GIVEN la variable de entorno `UI_PASSWORD` tiene un valor no vacío
- WHEN el entrypoint construye el comando de arranque de OpenChamber
- THEN el flag `--ui-password "$UI_PASSWORD"` se incluye en el comando final

#### Scenario: UI_PASSWORD vacío emite warning y continúa

- GIVEN la variable de entorno `UI_PASSWORD` está vacía o no está definida
- WHEN el entrypoint ejecuta su lógica de arranque
- THEN escribe un warning legible a stderr
- AND el contenedor continúa iniciando OpenChamber sin flag `--ui-password`

#### Scenario: Variables upstream pasan por entorno

- GIVEN variables de entorno soportadas por OpenChamber upstream están definidas
- WHEN el contenedor arranca
- THEN dichas variables permanecen disponibles en el entorno del proceso OpenChamber

#### Scenario: Comando final de OpenChamber incluye flags obligatorios

- GIVEN el entrypoint ha procesado la configuración y variables
- WHEN delega la ejecución a OpenChamber
- THEN el comando ejecutado es `openchamber serve --foreground --host <OPENCHAMBER_HOST> --port <OPENCHAMBER_PORT>`
- AND si aplica, incluye `--ui-password "$UI_PASSWORD"`

## ADDED Requirements

### Requirement: Resolución de directorio de configuración

El entrypoint MUST resolver `OPENCHAMBER_CONFIG_DIR` con default `~/.config/openchamber` para determinar dónde opera el seed/merge de configuración OpenCode.

#### Scenario: OPENCHAMBER_CONFIG_DIR no definido

- GIVEN `OPENCHAMBER_CONFIG_DIR` no está definido
- WHEN el entrypoint necesita la ruta de configuración
- THEN usa `~/.config/openchamber` como default

## REMOVED Requirements

Ninguno.
