# persistence Specification

## Purpose

Definir comportamiento observable de la persistencia de datos mediante volúmenes host montados en el contenedor.

## Requirements

### Requirement: Matriz de volúmenes completa

El sistema MUST permitir montar 10 volúmenes host en el contenedor según la matriz definida en PRD §325-338.

#### Scenario: Todos los volúmenes montados y datos sobreviven recreación

- GIVEN los 10 directorios host existen y `docker-compose.yml` los mapea correctamente
- WHEN el contenedor escribe archivos en cualquiera de los paths montados
- AND se ejecuta `docker compose down && docker compose up -d`
- THEN los archivos escritos permanecen en los directorios host
- AND el nuevo contenedor los ve en las mismas rutas contenedor

### Requirement: Permisos SSH estrictos

El directorio `~/.ssh` MUST tener permisos `700`, y los archivos de clave privada dentro MUST tener permisos `600`.

#### Scenario: init script corrige permisos SSH existentes

- GIVEN `data/ssh` contiene claves con permisos incorrectos
- WHEN `scripts/init-dirs.sh` ejecuta
- THEN `data/ssh` tiene permisos `700`
- AND los archivos de clave privada tienen permisos `600`

### Requirement: Inicialización de directorios

`scripts/init-dirs.sh` MUST crear los 10 directorios persistentes si no existen.

#### Scenario: Fresh clone con directorios ausentes

- GIVEN un clon fresco del repositorio sin directorios `data/` ni `workspaces/`
- WHEN se ejecuta `scripts/init-dirs.sh`
- THEN existen `data/openchamber`, `data/opencode/config`, `data/opencode/share`, `data/opencode/state`, `data/opencode/cache`, `data/agents`, `data/gh`, `data/ssh`, `data/opencode-multi-auth` y `workspaces`

### Requirement: Ownership correcto para usuario no-root

Los directorios de volúmenes MUST ser escritos por el usuario contenedor con UID 1000.

#### Scenario: Container puede escribir en volúmenes inicializados

- GIVEN `scripts/init-dirs.sh` creó los directorios
- WHEN el contenedor corre como usuario `openchamber` (UID 1000)
- THEN puede crear archivos en cualquiera de los paths montados
