# PRD: Dockerizar OpenCode + OpenChamber

## Resumen

Crear una imagen Docker propia para correr OpenCode + OpenChamber en VPS `linux/amd64` y `linux/arm64`, con `opencode-synced` habilitado para sincronizar configuración OpenCode desde la máquina local.

La imagen final se publicará en GHCR como:

```txt
ghcr.io/<owner>/opencode-openchamber
```

## Problema

Un usuario que ya usa OpenCode localmente tiene configuración, plugins, skills, agentes, temas y preferencias. Al mover su flujo a un VPS, no quiere reconstruir ese entorno a mano.

OpenChamber permite usar OpenCode desde web/PWA/remoto, pero no hay una imagen oficial verificada publicada para OpenChamber. OpenCode sí tiene imagen oficial Docker.

## Objetivos

- Publicar imagen propia multi-arch en GHCR para `linux/amd64` y `linux/arm64`.
- Instalar OpenCode desde npm usando `opencode-ai` con versión configurable.
- Instalar OpenChamber desde npm usando `@openchamber/web` con versión configurable.
- Habilitar `opencode-synced` en la configuración base de OpenCode para replicar configuración local al VPS.
- Permitir configuración por variables de entorno para `GH_TOKEN`, `UI_PASSWORD`, puerto y variables soportadas por OpenChamber upstream.
- Persistir configuración, estado, agentes, GitHub auth, SSH y workspaces mediante volúmenes host.
- Dar flujo simple para VPS: levantar contenedor, proteger UI con password, enlazar sync repo.
- Mantener compatibilidad con VPS ARM.

## Non-goals

- No modificar código fuente upstream de OpenChamber.
- No depender de `curl | bash` en build Docker.
- No compilar OpenChamber desde fuente.
- No usar `OPENCHAMBER_REF` ni builds desde branch/tag/commit upstream.
- No sincronizar secrets por default.
- No sincronizar sesiones por default.
- No recomendar exponer OpenChamber públicamente sin password.
- No crear una plataforma multiusuario/multi-tenant.

## Decisiones acordadas

### Stack tecnológico

- Base image: `node:22-bookworm-slim`.
- Runtime: Node.js 22 LTS sobre Debian/glibc.
- Package manager para CLIs globales: npm.
- OpenCode: `opencode-ai@${OPENCODE_VERSION}` instalado globalmente.
- OpenChamber: `@openchamber/web@${OPENCHAMBER_VERSION}` instalado globalmente.
- Bun: instalado explícitamente para compatibilidad con OpenCode plugins y runtime/cache de plugins.
- Dependencias OS mínimas: `bash`, `ca-certificates`, `git`, `gh`, `openssh-client`, `tini`.
- Usuario runtime: `openchamber` con UID/GID `1000`.
- Orquestación local/VPS: Docker Compose v2.
- Registry: GHCR.
- CI/CD: GitHub Actions + Docker Buildx + QEMU.
- Plataformas: `linux/amd64` y `linux/arm64`.
- No usar Alpine/musl en MVP por riesgo con dependencias nativas de OpenChamber (`better-sqlite3`, `node-pty`, `bun-pty`) y multi-arch.

### Imagen

- Nombre de imagen: `ghcr.io/<owner>/opencode-openchamber`.
- Publicación vía CI multi-arch con Docker Buildx.
- La imagen debe ser una sola imagen que contenga OpenCode, OpenChamber, Bun, `gh`, `git`, SSH client y configuración base para `opencode-synced`.
- No habrá una imagen/servicio separado de OpenCode CLI en MVP.
- Plataformas requeridas:
  - `linux/amd64`
  - `linux/arm64`

### Orden de instalación

El Dockerfile debe instalar/configurar en este orden:

0. Base y build args:

   ```Dockerfile
   FROM node:22-bookworm-slim
   ARG OPENCHAMBER_VERSION=latest
   ARG OPENCODE_VERSION=latest
   ```

1. OpenCode:

   ```bash
   npm install -g opencode-ai@${OPENCODE_VERSION:-latest}
   ```

2. OpenChamber:

   ```bash
   npm install -g @openchamber/web@${OPENCHAMBER_VERSION:-latest}
   ```

3. `opencode-synced`:

   - Crear o preparar la configuración base de OpenCode con el plugin habilitado.
   - Incluir `gh` y `git` porque el plugin los requiere.
   - OpenCode resolverá/instalará el plugin al arrancar con esa configuración.

`OPENCHAMBER_VERSION` y `OPENCODE_VERSION` son build args, no variables runtime. Cambiarlas requiere rebuild o usar una imagen ya publicada con otros pins.

### OpenChamber

- Usar paquete npm directo, no script de instalación:

  ```bash
  npm install -g @openchamber/web@${OPENCHAMBER_VERSION:-latest}
  ```

- Variable principal:

  ```txt
  OPENCHAMBER_VERSION=latest
  ```

  Esta variable debe usarse como build arg.

- El paquete npm `@openchamber/web` publica el binario `openchamber`.
- Comando runtime esperado:

  ```bash
  openchamber serve --foreground --host "${OPENCHAMBER_HOST:-0.0.0.0}" --port "${OPENCHAMBER_PORT:-3000}"
  ```

- Si `UI_PASSWORD` no está vacío, el entrypoint debe pasarlo a OpenChamber como:

  ```bash
  --ui-password "$UI_PASSWORD"
  ```

- OpenChamber también soporta `OPENCHAMBER_UI_PASSWORD` como alternativa upstream a `--ui-password`.

- No existe fallback build-from-source.
- No usar `OPENCHAMBER_REF`.
- Pasar por entorno las variables soportadas por OpenChamber upstream, incluyendo:
  - `OPENCHAMBER_HOST`
  - `OPENCHAMBER_DATA_DIR`
  - `OPENCHAMBER_TUNNEL_PROVIDER`
  - `OPENCHAMBER_TUNNEL_MODE`
  - `OPENCHAMBER_TUNNEL_HOSTNAME`
  - `OPENCHAMBER_TUNNEL_TOKEN`
  - `OPENCHAMBER_TUNNEL_CONFIG`
  - `OH_MY_OPENCODE`
  - `OPENCODE_HOST`
  - `OPENCODE_PORT`
  - `OPENCODE_SKIP_START`
  - `OPENCHAMBER_OPENCODE_HOSTNAME`
  - `OPENCHAMBER_UI_PASSWORD`
  - `UI_PASSWORD`

### OpenCode

- Instalar OpenCode dentro de la imagen vía npm:

  ```bash
  npm install -g opencode-ai@${OPENCODE_VERSION:-latest}
  ```

- El runtime debe tener OpenCode disponible para OpenChamber.
- Variable principal:

  ```txt
  OPENCODE_VERSION=latest
  ```

  Esta variable debe usarse como build arg.

- OpenCode usa configuración global en:

  ```txt
  ~/.config/opencode/opencode.json
  ~/.config/opencode/opencode.jsonc
  ```

- La imagen o entrypoint debe asegurar que `opencode-synced` esté presente en el arreglo `plugin` sin borrar configuración existente del usuario.

### opencode-synced

- Objetivo principal: replicar configuración local OpenCode al VPS.
- Debe sincronizar por default:
  - `~/.config/opencode/opencode.json` / `opencode.jsonc`
  - plugins
  - skills
  - agents
  - themes/modes/tools
  - model favorites
- No debe sincronizar por default:
  - secrets
  - MCP secrets
  - sessions
  - prompt stash
  - stores sensibles de plugins de auth/multi-auth
  - configuración propia de OpenChamber

Config base esperada:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": ["opencode-synced"]
}
```

Reglas de seed/merge:

- Si no existe `opencode.json` ni `opencode.jsonc`, crear `opencode.jsonc` con config base.
- Si ya existe configuración, agregar `opencode-synced` al arreglo `plugin` sin borrar otros campos.
- Si `opencode-synced` ya existe, no duplicarlo.
- `/sync-link` puede sobrescribir configuración local según comportamiento upstream; documentar antes de usarlo.

Flujo esperado:

```txt
Local: /sync-init
VPS:   /sync-link <repo>
```

Si el usuario quiere sesiones entre múltiples máquinas activas, documentar Turso como opción recomendada sobre Git:

```txt
/sync-sessions-backend turso
/sync-sessions-setup-turso
```

### Datos de plugins y stores sensibles

- `opencode-synced` se usará para configuración portable de OpenCode, no como backup completo de `$HOME`.
- No se debe sincronizar todo `~/.config` ni todo `~/.local/share` por default.
- OpenChamber guarda configuración fuera de OpenCode; debe persistirse por volumen, no por `opencode-synced`.
- Plugins de auth/multi-auth pueden guardar tokens/cuentas OAuth en stores propios, por ejemplo:

  ```txt
  ~/.config/opencode-multi-auth/accounts.json
  ~/.config/opencode/opencode-multi-auth-codex-accounts.json
  ```

- Esos stores son sensibles y deben persistirse localmente en el VPS por volumen, pero no sincronizarse por Git default.
- Si el usuario decide sincronizarlos, sólo debe hacerlo explícitamente con `extraSecretPaths`, repo privado y entendiendo que contiene tokens/refresh tokens.
- Recomendación MVP: reautenticar esos plugins en el VPS o usar stores locales persistidos, no sync Git.

### Acceso

- Local: el usuario puede elegir cualquier modo soportado por OpenChamber.
- Cloud/VPS: default será puerto directo con password.
- `UI_PASSWORD` debe estar documentado como recomendado fuerte para despliegues cloud.
- Si `UI_PASSWORD` está vacío, el entrypoint debe emitir warning visible en logs y continuar.
- No validar fuerza ni longitud de password en MVP.

## Arquitectura objetivo

```txt
LOCAL MACHINE
┌──────────────────────────────────────────────┐
│ OpenCode local                               │
│ ~/.config/opencode                           │
│ ~/.agents                                    │
│ plugins / skills / themes / modes            │
└───────────────┬──────────────────────────────┘
                │ /sync-init or /sync-push
                ▼
        GitHub private sync repo
        my-opencode-config
                ▲
                │ /sync-link or startup sync
┌───────────────┴──────────────────────────────┐
│ VPS linux/amd64 or linux/arm64               │
│                                              │
│ ┌──────────────────────────────────────────┐ │
│ │ ghcr.io/<owner>/opencode-openchamber     │ │
│ │ OpenChamber web :3000                    │ │
│ │ OpenCode runtime via opencode-ai npm     │ │
│ │ opencode-synced enabled in config        │ │
│ │ gh + git + ssh client                    │ │
│ └──────────────────────────────────────────┘ │
│                                              │
│ data/openchamber                             │
│ data/opencode/config                         │
│ data/opencode/share                          │
│ data/opencode/state                          │
│ data/opencode/cache                          │
│ data/agents                                  │
│ data/gh                                      │
│ data/ssh                                     │
│ data/opencode-multi-auth                     │
│ workspaces                                   │
└──────────────────────────────────────────────┘
```

## Requisitos funcionales

### Bootstrap

- El usuario debe poder copiar `.env.example` a `.env`.
- El usuario debe poder inicializar directorios persistentes con script local.
- El usuario debe poder levantar OpenChamber con:

  ```bash
  docker compose up -d openchamber
  ```

- El usuario debe poder abrir UI en:

  ```txt
  http://<vps-ip>:${OPENCHAMBER_PORT}
  ```

### Sincronización

- Primera máquina local debe poder crear repo privado de sync con `/sync-init`.
- VPS debe poder enlazarse con `/sync-link`.
- El contenedor debe incluir `gh` y `git` porque `opencode-synced` los requiere.
- `GH_TOKEN` debe permitir auth headless en VPS cuando el usuario no quiera login interactivo.
- La imagen debe incluir configuración base con `plugin: ["opencode-synced"]`.

### Persistencia

- OpenChamber config debe sobrevivir recreación del contenedor.
- OpenCode config/state/share deben sobrevivir recreación del contenedor.
- OpenCode cache debe sobrevivir recreación del contenedor para evitar reinstalar plugins/cache innecesariamente.
- Agents deben sobrevivir recreación del contenedor.
- GitHub CLI auth debe sobrevivir recreación del contenedor.
- SSH keys/config deben sobrevivir recreación del contenedor.
- Stores locales sensibles de plugins multi-auth seleccionados deben sobrevivir recreación del contenedor.
- Workspaces deben ser volumen host.

Matriz esperada:

| Host | Contenedor |
|---|---|
| `data/openchamber` | `/home/openchamber/.config/openchamber` |
| `data/opencode/config` | `/home/openchamber/.config/opencode` |
| `data/opencode/share` | `/home/openchamber/.local/share/opencode` |
| `data/opencode/state` | `/home/openchamber/.local/state/opencode` |
| `data/opencode/cache` | `/home/openchamber/.cache/opencode` |
| `data/agents` | `/home/openchamber/.agents` |
| `data/gh` | `/home/openchamber/.config/gh` |
| `data/ssh` | `/home/openchamber/.ssh` |
| `data/opencode-multi-auth` | `/home/openchamber/.config/opencode-multi-auth` |
| `workspaces` | `/home/openchamber/workspaces` |

### Seguridad

- `UI_PASSWORD` debe estar documentado como recomendado fuerte para cloud.
- `UI_PASSWORD` vacío debe generar warning visible en logs.
- `includeSecrets` debe ser `false` por default.
- `includeSessions` debe ser `false` por default.
- `includePromptStash` debe ser `false` por default.
- Stores de plugins multi-auth deben tratarse como secretos y no sincronizarse por default.
- Documentar que secrets sólo deben activarse si el sync repo es privado.
- Documentar que `extraSecretPaths` es opt-in avanzado para stores sensibles y debe usarse sólo con repo privado.

## Requisitos no funcionales

- Imagen multi-arch debe publicar manifests para `linux/amd64` y `linux/arm64`.
- Builds deben ser reproducibles mediante versiones pinneables:
  - `OPENCHAMBER_VERSION`
  - `OPENCODE_VERSION`
- CI debe verificar manifest multi-arch después de publicar.
- Docs deben explicar diferencia entre sync de config y sync de sessions/secrets.
- Docs deben explicar diferencia entre persistencia local por volumen y sincronización Git vía `opencode-synced`.

## CI/CD esperado

Triggers sugeridos:

- Push a `main`.
- Tags `v*`.
- Manual workflow dispatch con `OPENCHAMBER_VERSION` y `OPENCODE_VERSION` override.

Tags mínimos MVP:

```txt
ghcr.io/<owner>/opencode-openchamber:latest
ghcr.io/<owner>/opencode-openchamber:main
ghcr.io/<owner>/opencode-openchamber:sha-<shortsha>
ghcr.io/<owner>/opencode-openchamber:openchamber-<openchamber-version>-opencode-<opencode-version>
```

Tags opcionales futuros:

```txt
ghcr.io/<owner>/opencode-openchamber:openchamber-<version>
ghcr.io/<owner>/opencode-openchamber:opencode-<version>
ghcr.io/<owner>/opencode-openchamber:v<semver>
```

Buildx plataformas:

```txt
linux/amd64,linux/arm64
```

## Política de actualización

- Inicialmente las actualizaciones serán manuales vía `workflow_dispatch`.
- `workflow_dispatch` debe aceptar overrides explícitos para:
  - `OPENCHAMBER_VERSION`
  - `OPENCODE_VERSION`
- No debe existir auto-merge por default.
- Cada actualización debe pasar por PR/revisión y validación CI antes de publicarse como release recomendado.
- Dependabot puede habilitarse para:
  - GitHub Actions.
  - Docker base images.
  - Alertas de seguridad.
- Renovate queda como opción recomendada futura para automatizar pins custom como:
  - `OPENCHAMBER_VERSION`
  - `OPENCODE_VERSION`
- Si se habilita Renovate, debe agrupar updates relacionados y evitar majors automáticos sin revisión explícita.

## Política de pins para producción

- Para quickstart/dev se permiten defaults `latest`:
  - `OPENCHAMBER_VERSION=latest`
  - `OPENCODE_VERSION=latest`
- Para producción se recomiendan versiones npm exactas:
  - `OPENCHAMBER_VERSION=<versión exacta>`
  - `OPENCODE_VERSION=<versión exacta>`
- Las imágenes publicadas con versiones exactas deben tener tag que incluya ambas versiones cuando aplique:

  ```txt
  ghcr.io/<owner>/opencode-openchamber:openchamber-<openchamber-version>-opencode-<opencode-version>
  ```
- La documentación debe explicar que `latest` prioriza comodidad, no reproducibilidad.

## Variables esperadas

```env
# Runtime: OpenChamber HTTP port exposed by Docker Compose.
OPENCHAMBER_PORT=3000

# Build arg: @openchamber/web npm version. Requires rebuild to change.
OPENCHAMBER_VERSION=latest

# Build arg: opencode-ai npm version. Requires rebuild to change.
OPENCODE_VERSION=latest

# Runtime: preferred project-level password var. Entrypoint maps it to --ui-password.
UI_PASSWORD=

# Runtime: upstream OpenChamber alternative to --ui-password.
OPENCHAMBER_UI_PASSWORD=

# Runtime: optional GitHub token for gh/GitHub CLI headless auth flows.
GH_TOKEN=

# Runtime: OpenChamber bind address inside container.
OPENCHAMBER_HOST=0.0.0.0

# Runtime: optional OpenChamber data dir override.
OPENCHAMBER_DATA_DIR=

# Runtime: managed OpenCode server bind hostname.
OPENCHAMBER_OPENCODE_HOSTNAME=0.0.0.0

# Runtime: external OpenCode server URL. Takes precedence over OPENCODE_PORT upstream.
OPENCODE_HOST=

# Runtime: external/managed OpenCode port.
OPENCODE_PORT=

# Runtime: true when OpenChamber should connect to external OpenCode and not start one.
OPENCODE_SKIP_START=false

# Runtime: Cloudflare tunnel provider.
OPENCHAMBER_TUNNEL_PROVIDER=

# Runtime: tunnel mode quick | managed-remote | managed-local.
OPENCHAMBER_TUNNEL_MODE=

# Runtime: managed-remote hostname.
OPENCHAMBER_TUNNEL_HOSTNAME=

# Runtime: managed-remote token.
OPENCHAMBER_TUNNEL_TOKEN=

# Runtime: managed-local config path inside container.
OPENCHAMBER_TUNNEL_CONFIG=

# Runtime: enable upstream oh-my-opencode setup.
OH_MY_OPENCODE=false
```

## Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| OpenChamber no tiene imagen oficial verificada | Publicar imagen propia GHCR multi-arch |
| `curl | bash` cambia sin control | Usar `npm install -g @openchamber/web@${OPENCHAMBER_VERSION}` |
| Build rompe por versión flotante | Permitir default `latest` para comodidad, pero documentar pins `OPENCHAMBER_VERSION` y `OPENCODE_VERSION` para producción |
| `/sync-link` sobrescribe config local | Documentar antes del comando; preservar overrides |
| Secrets filtrados | `includeSecrets: false` por default |
| Stores multi-auth filtrados | Persistir por volumen local; no sincronizar por Git default |
| Sesiones con conflictos Git | No sincronizar sessions por default; recomendar Turso si aplica |
| OpenChamber config no sincronizada | Persistir `~/.config/openchamber` por volumen host |
| Puerto expuesto en VPS | `UI_PASSWORD` recomendado fuerte; warning visible si vacío |
| ARM falla por dependencia nativa | CI buildx + manifest inspect para amd64/arm64 |
| Alpine/musl rompe dependencias nativas | Usar `node:22-bookworm-slim` basado en Debian/glibc |

## Preguntas abiertas

- Ninguna por ahora.

## Criterios de aceptación

- CI publica `ghcr.io/<owner>/opencode-openchamber` para `linux/amd64` y `linux/arm64`.
- Un VPS ARM puede hacer pull y levantar OpenChamber.
- OpenChamber escucha en `OPENCHAMBER_PORT` y usa password cuando `UI_PASSWORD` está configurado.
- Si `UI_PASSWORD` está vacío, el contenedor emite warning visible en logs.
- Si `UI_PASSWORD` está configurado, el entrypoint lo inyecta a OpenChamber como `--ui-password`.
- El contenedor incluye OpenCode instalado vía `opencode-ai`, OpenChamber instalado vía `@openchamber/web`, `gh`, `git`, SSH client y `opencode-synced` habilitado en config base.
- Usuario puede ejecutar `/sync-link <repo>` en VPS y obtener config/plugins/agents del OpenCode local.
- Configuración, estado, cache, agents, GitHub auth, SSH, stores multi-auth seleccionados y workspaces persisten tras recrear contenedor.
- Docs indican que `opencode-synced` no sincroniza todo `~/.config` ni todo `~/.local/share` por default.
- Docs indican que stores multi-auth/tokens son sensibles y sólo deben sincronizarse con `extraSecretPaths` si el usuario lo activa explícitamente en repo privado.
