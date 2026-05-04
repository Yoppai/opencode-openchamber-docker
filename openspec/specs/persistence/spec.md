# persistence Specification

## Purpose
MODIFIED: Simplificar matriz de volúmenes de 10 mounts a 2 usando directorios padres.

## Requirements

### Requirement: Matriz de volúmenes simplificada (MODIFIED)
El compose MUST definir 2 bind mounts:
1. `./data/home:/home/openchamber` — persiste config, cache, state, agents, auth, plugins
2. `./workspaces:/home/openchamber/workspaces` — código fuente separado

#### Scenario: Mounts definidos correctamente
- GIVEN `docker-compose.yml`
- WHEN se inspeccionan los volumes
- THEN hay exactamente 2 bind mounts
- AND el mount `data/home` apunta a `/home/openchamber`
- AND el mount `workspaces` apunta a `/home/openchamber/workspaces`

### Requirement: Persistencia de home completo
El mount `data/home` MUST preservar todo el contenido de `/home/openchamber` tras recrear el contenedor.

#### Scenario: Config sobrevive recreate
- GIVEN un contenedor con datos escritos en `~/.config/opencode/opencode.jsonc`
- WHEN se ejecuta `docker compose down && docker compose up -d`
- THEN `~/.config/opencode/opencode.jsonc` conserva el contenido anterior

#### Scenario: Auth sobrevive recreate
- GIVEN `gh auth login` ejecutado dentro del contenedor
- WHEN se recrea el contenedor
- THEN `gh auth status` reporta sesión activa

#### Scenario: Plugins sobreviven recreate
- GIVEN un plugin instalado que escribe en `~/.agent-browser/` o `~/.agents/`
- WHEN se recrea el contenedor
- THEN los datos del plugin persisten

### Requirement: Workspaces separado
El mount `workspaces` MUST ser independiente de `data/home` para gestión separada de código fuente.

#### Scenario: Workspaces no se mezcla con config
- GIVEN `workspaces/` contiene proyectos clonados
- WHEN se borra `data/home/` (reset de config)
- THEN `workspaces/` permanece intacto

### Requirement: SSH permisos defensivos (MODIFIED)
SSH keys viven dentro de `data/home/.ssh/`. El entrypoint MUST aplicar `chmod 700` no silencioso.

#### Scenario: Permisos SSH corregidos con warning
- GIVEN `~/.ssh/` existe dentro del home montado
- WHEN el entrypoint intenta `chmod 700`
- THEN si falla, emite warning visible en stderr
- AND el contenedor continúa iniciando

### Requirement: Inicialización simplificada
`init-dirs.sh` MUST crear `data/home/` y `workspaces/` (no los 10 directorios anteriores).

#### Scenario: Init script crea 2 directorios
- GIVEN un clone fresco del proyecto
- WHEN se ejecuta `scripts/init-dirs.sh`
- THEN `data/home/` y `workspaces/` existen
