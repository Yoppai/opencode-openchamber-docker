# Delta for vps-quickstart

## ADDED Requirements

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
