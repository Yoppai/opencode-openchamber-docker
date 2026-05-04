# Delta for runtime-config

## ADDED Requirements

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
