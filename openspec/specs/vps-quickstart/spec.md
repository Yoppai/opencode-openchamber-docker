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

### Requirement: REQ-DOC-QUICKSTART-SYNC Incluir pasos de sincronización en quickstart

La documentación de quickstart MUST incluir una sección de configuración de sincronización después del bootstrap inicial del contenedor.

#### Scenario: Sección de sync visible tras bootstrap

- DADO que el usuario completó `docker compose up -d openchamber` siguiendo el quickstart
- CUANDO continúa leyendo la guía
- ENTONCES encuentra una sección dedicada a la configuración de `opencode-synced` con los pasos siguientes a seguir

#### Scenario: Quickstart enlaza a documentación completa de sync

- DADO que el usuario lee la sección de sincronización dentro del quickstart
- CUANDO necesita más detalle sobre el flujo completo
- ENTONCES la documentación proporciona un enlace directo a la guía completa de sincronización (`sync-flow.md` o equivalente)
