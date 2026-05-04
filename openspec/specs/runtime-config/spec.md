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

### Requirement: Entrypoint como punto de arranque del contenedor
El contenedor MUST ejecutar un entrypoint script al iniciar. Este script MUST leer variables de entorno runtime, preparar la configuración de OpenCode, y lanzar OpenChamber con los flags correctos.

#### Scenario: Entrypoint ejecutado por tini como PID 1

- GIVEN un contenedor iniciado
- WHEN se inspecciona el proceso con PID 1
- THEN el PID 1 es `tini`, que ejecuta el entrypoint, el cual mediante `exec` lanza `openchamber` como proceso hijo

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

### Requirement: Resolución de directorio de configuración
El entrypoint MUST resolver `OPENCHAMBER_CONFIG_DIR` con default `~/.config/opencode` para determinar dónde opera el seed/merge de configuración OpenCode (`opencode.json`/`opencode.jsonc`).

#### Scenario: OPENCHAMBER_CONFIG_DIR no definido

- GIVEN `OPENCHAMBER_CONFIG_DIR` no está definido
- WHEN el entrypoint necesita la ruta de configuración
- THEN usa `~/.config/opencode` como default

### Requirement: Resolución de OPENCHAMBER_CONFIG_DIR con volúmenes

El entrypoint MUST resolver `OPENCHAMBER_CONFIG_DIR` dentro de un volumen montado desde host. Cuando `OPENCHAMBER_CONFIG_DIR` no está definido, el default `~/.config/opencode` debe corresponder al volumen host mapeado en `docker-compose.yml`.

#### Scenario: Config dir default coincide con volumen montado

- GIVEN `docker-compose.yml` monta `data/opencode/config` en `/home/openchamber/.config/opencode`
- AND `OPENCHAMBER_CONFIG_DIR` no está definido
- WHEN el entrypoint resuelve el directorio de configuración
- THEN usa `/home/openchamber/.config/opencode`
- AND dicho path es un bind mount desde el host

### Requirement: Corrección defensiva de permisos

El entrypoint SHOULD ejecutar `chmod 700` sobre `~/.ssh` al arrancar si el directorio existe, como medida defensiva ante mounts con permisos incorrectos.

#### Scenario: Volume SSH montado con permisos incorrectos

- GIVEN `~/.ssh` existe y está montado desde host
- AND tiene permisos distintos de `700`
- WHEN el entrypoint ejecuta su lógica de arranque
- THEN corrige los permisos de `~/.ssh` a `700` antes de lanzar OpenChamber
