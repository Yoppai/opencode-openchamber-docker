# vps-quickstart Specification

## Purpose

Definir el flujo de bootstrap observable para nuevos usuarios que despliegan OpenChamber en VPS.

## Requirements

### Requirement: Secuencia de bootstrap

El usuario MUST poder desplegar OpenChamber siguiendo: copiar `.env.example` a `.env`, ejecutar `scripts/init-dirs.sh`, y `docker compose up -d openchamber`.

#### Scenario: Fresh VPS con pasos de quickstart

- GIVEN un servidor fresco con Docker y Docker Compose v2 instalados
- WHEN el usuario ejecuta `cp .env.example .env`, `./scripts/init-dirs.sh` y `docker compose up -d openchamber`
- THEN el servicio arranca sin errores
- AND OpenChamber está escuchando en el puerto configurado

### Requirement: Variables documentadas en .env.example

`.env.example` MUST incluir todas las variables runtime con comentarios explicando su propósito.

#### Scenario: Usuario revisa .env.example

- GIVEN el archivo `.env.example` en el repositorio
- WHEN un usuario lo abre
- THEN cada variable runtime tiene un comentario descriptivo
- AND no contiene valores sensibles reales

### Requirement: UI accessible tras bootstrap

Tras `docker compose up -d`, la UI de OpenChamber MUST ser alcanzable en `http://<ip>:<OPENCHAMBER_PORT>`.

#### Scenario: Verificación de acceso post-bootstrap

- GIVEN `docker compose up -d openchamber` completó exitosamente
- WHEN se ejecuta `curl http://localhost:<OPENCHAMBER_PORT>` desde el host
- THEN retorna una respuesta HTTP válida (cualquier código 2xx, 3xx o la página de login de OpenChamber)

### Requirement: Reinicio post-reboot

El servicio `openchamber` en `docker-compose.yml` MUST configurarse con `restart: unless-stopped` para sobrevivir reinicios del daemon Docker.

#### Scenario: Servidor reinicia

- GIVEN el contenedor está corriendo con `restart: unless-stopped`
- WHEN el servidor se reinicia y Docker daemon arranca
- THEN el contenedor `openchamber` se inicia automáticamente
- AND está en estado `running` al consultar `docker ps`
