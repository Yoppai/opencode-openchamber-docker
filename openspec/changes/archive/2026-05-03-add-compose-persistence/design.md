# Design: add-compose-persistence (ch-04)

## Technical Approach

Orquestar OpenChamber con Docker Compose v2 usando `build: .` por defecto, 10 bind mounts host→contenedor según matriz PRD §325-338, variables runtime vía `env_file: .env`, y un script `init-dirs.sh` que bootstraptea directorios con permisos SSH correctos antes del primer `docker compose up`.

### docker-compose.yml

Servicio único `openchamber` con:

- `build: .` — default local build (alternativa `image:` comentada para ch-06).
- `container_name: openchamber` — nombre estable para logs y healthcheck.
- `restart: unless-stopped` — recuperación automática en VPS.
- `ports: ["${OPENCHAMBER_PORT:-3000}:8080"]` — host port configurable vía env; contenedor escucha en 8080 (default entrypoint).
- `env_file: .env` — carga todas las variables runtime; compose las pasa al contenedor.
- 10 `volumes` tipo bind mount relativo (`./data/...` y `./workspaces`).
- `healthcheck`: `curl -sf http://localhost:8080/` con `start_period: 10s`. Un 401 significa que el servidor HTTP está vivo; cualquier respuesta HTTP (incluso error) indica que el proceso no ha crashado. `start_period` da margen al entrypoint para seed/merge de config.

### .env.example

Variables agrupadas por dominio, todas comentadas con descripción y default:

1. **OpenChamber core**: `OPENCHAMBER_PORT`, `OPENCHAMBER_HOST`, `OPENCHAMBER_DATA_DIR`, `UI_PASSWORD`, `OPENCHAMBER_UI_PASSWORD`
2. **OpenCode bridge**: `OPENCHAMBER_OPENCODE_HOSTNAME`, `OPENCODE_HOST`, `OPENCODE_PORT`, `OPENCODE_SKIP_START`
3. **Tunnel**: `OPENCHAMBER_TUNNEL_PROVIDER`, `OPENCHAMBER_TUNNEL_MODE`, `OPENCHAMBER_TUNNEL_HOSTNAME`, `OPENCHAMBER_TUNNEL_TOKEN`, `OPENCHAMBER_TUNNEL_CONFIG`
4. **GitHub / misc**: `GH_TOKEN`, `OH_MY_OPENCODE`

`OPENCHAMBER_VERSION` y `OPENCODE_VERSION` se omiten (son build args). Cada línea tiene formato `VAR=default # descripción`.

### scripts/init-dirs.sh

Script bash con `set -euo pipefail`. Crea la jerarquía:

```bash
mkdir -p data/openchamber
mkdir -p data/opencode/{config,share,state,cache}
mkdir -p data/agents
mkdir -p data/gh
mkdir -p data/ssh
mkdir -p data/opencode-multi-auth
mkdir -p workspaces
```

Luego aplica permisos SSH:

```bash
chmod 700 data/ssh
```

No toma argumentos. Se ejecuta desde project root. En Windows nativo el `chmod` es no-op efectivo; el contenedor Linux dentro de Docker Desktop heredará ownership root si Docker crea los dirs, pero el entrypoint hace `chmod 700` defensivo al arrancar (ver delta).

### entrypoint.sh (delta)

Añadir bloque defensivo antes de `exec openchamber serve`:

```bash
# --- Defensive SSH permissions ---
if [ -d "$HOME/.ssh" ]; then
  chmod 700 "$HOME/.ssh"
fi
```

Rationale: si Docker creó `data/ssh` como root (porque no existía antes del primer mount), el bind mount hereda ownership root. El contenedor corre como `openchamber` (UID 1000). El entrypoint puede leer/escribir si los permisos host son 700, pero el `chmod` defensivo asegura que ssh no rechace la carpeta por permisos abiertos.

## Architecture Decisions

### AD-1: Compose v2 con `build: .` (local build) como default

| Aspecto | Decisión |
|---------|----------|
| **Elección** | `build: .` por defecto; bloque `image:` comentado para ch-06 |
| **Alternativas** | `image: ghcr.io/...` por default; requiere CI publicado (ch-06) |
| **Rationale** | MVP prioriza que un dev clone y levante sin depender de GHCR. El bloque comentado facilita el switch futuro. |
| **Tradeoff** | Build local toma ~1-3 min primer arranque; evita depender de registry externo. |

### AD-2: Single service `openchamber` (no multi-service compose)

| Aspecto | Decisión |
|---------|----------|
| **Elección** | Un solo servicio; OpenChamber + OpenCode coexisten en el mismo contenedor |
| **Alternativas** | Separar OpenCode en servicio aparte con networking interna |
| **Rationale** | OpenChamber está diseñado para gestionar OpenCode localmente; separar rompería el modelo de proceso hijo. No hay beneficio en complejidad multi-service. |

### AD-3: Relative bind mounts (`./data/*`)

| Aspecto | Decisión |
|---------|----------|
| **Elección** | Bind mounts relativos desde project root |
| **Alternativas** | Named volumes Docker (`volumes:` top-level); paths absolutos host |
| **Rationale** | Bind mounts permiten al usuario ver/modificar ficheros directamente (SSH keys, config). Paths relativos funcionan en cualquier directorio clone. Named volumes ocultan datos en Docker internals. |
| **Tradeoff** | Windows requiere WSL o Docker Desktop con file sharing habilitado. Documentado. |

### AD-4: HEALTHCHECK con curl a root

| Aspecto | Decisión |
|---------|----------|
| **Elección** | `curl -sf http://localhost:8080/`; 401 se considera healthy |
| **Alternativas** | Healthcheck TCP solo (`nc -z localhost 8080`); endpoint `/health` dedicado |
| **Rationale** | OpenChamber no expone `/health` conocido. Un TCP check solo valida que el puerto está abierto, no que el proceso HTTP responde. curl con `-f` falla en 5xx/connection refused, pero NO en 401 porque `-f` considera 4xx como fallo. Por eso se usa `curl -s -o /dev/null -w "%{http_code}"` y se acepta cualquier código 1xx-5xx como "servidor vivo". |
| **Nota** | `start_period: 10s` evita que Docker marque unhealthy mientras el entrypoint hace seed/merge. |

### AD-5: `env_file: .env` con `.env.example` documentado

| Aspecto | Decisión |
|---------|----------|
| **Elección** | `env_file: .env` en compose; `.env.example` versionado como template |
| **Alternativas** | Variables inline en `environment:` dentro de `docker-compose.yml` |
| **Rationale** | Separa secrets/valores sensibles del YAML versionado. `.gitignore` ya excluye `.env`. El usuario hace `cp .env.example .env` y modifica. |

### AD-6: `init-dirs.sh` en `scripts/` (no root)

| Aspecto | Decisión |
|---------|----------|
| **Elección** | `scripts/init-dirs.sh` |
| **Alternativas** | `init-dirs.sh` en project root; lógica dentro del entrypoint |
| **Rationale** | Consistente con `scripts/validate-*.sh` existentes. No meter lógica de creación de dirs host dentro del contenedor (el contenedor no debe asumir estructura host). |

## Data Flow

```
[Usuario]
   │
   ▼
[scripts/init-dirs.sh] ──► crea ./data/* y ./workspaces
   │                         chmod 700 data/ssh
   ▼
[cp .env.example .env] ──► usuario edita valores
   │
   ▼
[docker compose up -d]
   │
   ├──► build image (si build: .)
   │
   ├──► crea contenedor openchamber
   │       ├──► mount 10 bind volumes host→contenedor
   │       └──► env_file .env → variables de entorno
   │
   ├──► tini (PID 1) → entrypoint.sh
   │       ├──► seed/merge opencode.jsonc
   │       ├──► chmod 700 ~/.ssh (defensivo)
   │       └──► exec openchamber serve --foreground
   │
   └──► healthcheck curl localhost:8080 cada 30s
   │
   ▼
[OpenChamber accesible en http://<host>:<OPENCHAMBER_PORT>]
```

## File Changes

| File | Action | Purpose |
|---|---|---|
| `docker-compose.yml` | CREATE | Compose v2 service definition con volúmenes, healthcheck, env_file |
| `.env.example` | CREATE | Runtime variables documentadas (18 vars) |
| `scripts/init-dirs.sh` | CREATE | Bootstrap de directorios persistentes con permisos SSH |
| `entrypoint.sh` | MODIFY | Defensive `chmod 700` en `~/.ssh` al arrancar |

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Script | `init-dirs.sh` crea dirs correctos | Run script, assert `test -d data/ssh && stat -c %a data/ssh = 700` |
| Integration | `docker compose up -d` levanta sin error | Run compose, `docker compose ps` shows healthy |
| Integration | Persistencia tras recreate | `docker compose down && docker compose up -d`, assert files en `data/` persisten |
| Integration | SSH permissions inside container | `docker exec openchamber stat -c %a /home/openchamber/.ssh` = 700 |
| E2E | UI accesible | `curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT` retorna 401 (con password) o 200 (sin) |

## Risks

| Risk | Mitigation |
|---|---|
| SSH permissions incorrectos en Windows | Documentar WSL/Linux requirement. `init-dirs.sh` detecta OS (`uname -s`) y salta `chmod` en Windows (opcional). Entrypoint hace `chmod` defensivo dentro del contenedor Linux. |
| Volume ownership mismatch (root vs UID 1000) | `init-dirs.sh` crea dirs antes de compose para que el usuario los controle. Entrypoint `chmod` como segunda línea. |
| Compose build falla sin Docker | Documentar prerequisito Docker Engine + Docker Compose v2. |
| Healthcheck marca unhealthy con password | curl acepta cualquier código HTTP; `start_period` da tiempo al entrypoint. |
| `.env` con secrets commiteado | `.gitignore` ya excluye `.env`. `.env.example` no contiene valores sensibles reales. |

## Open Questions Resolved

1. **Healthcheck endpoint**: OpenChamber no expone `/health` dedicado. Se usa `curl` a `http://localhost:8080/`. Un 401 (autenticación requerida) confirma que el servidor HTTP está vivo. Cualquier respuesta HTTP válida (códigos 1xx-5xx) indica healthy; solo connection refused o timeout indican unhealthy.

2. **Image tag strategy**: `build: .` es el default. Se incluye bloque `image:` comentado (`# image: ghcr.io/...`) para facilitar el switch en ch-06 cuando GHCR publishing esté disponible.

3. **OPENCODE_BINARY path**: Está hardcodeado en Dockerfile como `ENV OPENCODE_BINARY=/usr/local/bin/opencode`. No requiere cambio; es estático.

4. **init-dirs.sh location**: `scripts/init-dirs.sh` para consistencia con `scripts/validate-*.sh` existentes. Se documentará en README en ch-07.

5. **Windows path compatibility**: Docker Desktop en Windows maneja bind mounts vía WSL2 backend o file sharing. El `chmod` de `init-dirs.sh` es no-op efectivo en Windows nativo. Documentar: usuarios Windows deben usar WSL2 o ignorar el paso de permisos. El entrypoint Linux ejecuta `chmod` defensivo dentro del contenedor.

6. **Volume first-creation**: Docker crea directorios de bind mount inexistentes como root. `init-dirs.sh` previene esto creando los dirs antes de `docker compose up`. El entrypoint hace `chmod` defensivo como segunda medida.

7. **Tunnel variables**: Las 5 variables (`OPENCHAMBER_TUNNEL_PROVIDER`, `_MODE`, `_HOSTNAME`, `_TOKEN`, `_CONFIG`) se incluyen en `.env.example`. Compose las pasa automáticamente al contenedor vía `env_file: .env`.
