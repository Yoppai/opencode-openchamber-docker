# Tasks: add-compose-persistence

## Phase 1: Docker Compose

- [x] 1.1 Crear `docker-compose.yml` con servicio `openchamber`: `build: .`, `container_name: openchamber`, `restart: unless-stopped`, `ports: ["${OPENCHAMBER_PORT:-3000}:${OPENCHAMBER_PORT:-8080}"]`, `env_file: .env`, 10 `volumes` tipo bind mount relativos (`./data/...`, `./workspaces`), `healthcheck` con `curl` a `localhost:${OPENCHAMBER_PORT:-8080}` y `start_period: 10s`
- [x] 1.2 Verificar sintaxis de `docker-compose.yml` ejecutando `docker compose config` (sin construir imagen)

## Phase 2: Environment & Init Script

- [x] 2.1 Crear `.env.example` con 17 variables runtime documentadas, agrupadas por propósito (OpenChamber core, OpenCode bridge, Tunnel, GitHub/misc), omitiendo build args `OPENCHAMBER_VERSION` y `OPENCODE_VERSION`
- [x] 2.2 Verificar que `.env.example` incluye nota explícita de que `OPENCHAMBER_VERSION` y `OPENCODE_VERSION` son build args (no runtime) y no deben estar en `.env`
- [x] 2.3 Crear `scripts/init-dirs.sh` con `set -euo pipefail`, 10 comandos `mkdir -p` (`data/openchamber`, `data/opencode/{config,share,state,cache}`, `data/agents`, `data/gh`, `data/ssh`, `data/opencode-multi-auth`, `workspaces`), `chmod 700 data/ssh`, y mensaje de feedback al usuario
- [x] 2.4 Hacer `scripts/init-dirs.sh` ejecutable con `chmod +x`

## Phase 3: Entrypoint Defense

- [x] 3.1 Modificar `entrypoint.sh`: añadir bloque defensivo `chmod 700 "$HOME/.ssh"` (solo si el directorio existe) después del seed/merge de config y antes de la resolución de password
- [x] 3.2 Verificar sintaxis de `entrypoint.sh` con `shellcheck` o `bash -n` tras la modificación

## Phase 4: Testing / Verification

- [ ] 4.1 Ejecutar `scripts/init-dirs.sh` en project root y validar que los 10 directorios existen y `data/ssh` tiene permisos `700`
- [ ] 4.2 Construir imagen y levantar servicio con `docker compose up -d openchamber`, verificar con `docker compose ps` que el contenedor está `running` y `healthy`
- [ ] 4.3 Validar persistencia: escribir un archivo de prueba en `data/openchamber/test.txt`, ejecutar `docker compose down && docker compose up -d`, y confirmar que el archivo sigue existiendo
- [ ] 4.4 Validar permisos SSH dentro del contenedor: `docker exec openchamber stat -c %a /home/openchamber/.ssh` debe retornar `700`
- [ ] 4.5 Validar acceso UI: `curl -s -o /dev/null -w "%{http_code}" http://localhost:$OPENCHAMBER_PORT` debe retornar cualquier código HTTP válido (incluido 401)
