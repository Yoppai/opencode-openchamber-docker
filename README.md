# OpenChamber Docker

Despliegue containerizado de OpenChamber con Docker Compose.
Incluye configuración automática de OpenCode con `opencode-synced` para sincronización multi-máquina.

## Quickstart

```bash
$ cp .env.example .env
$ ./scripts/init-dirs.sh
$ docker compose up -d openchamber
```

Ver [vps-quickstart spec](openspec/specs/vps-quickstart/spec.md) para detalles del bootstrap.

## Sincronización de configuración

`opencode-synced` replica configuración de OpenCode entre máquina local y VPS via Git.

```bash
# Local: inicializar repositorio
/sync-init

# VPS: clonar configuración desde remote
/sync-link https://github.com/tu-usuario/tu-repo.git
```

**Documentación completa**: [docs/sync-flow.md](docs/sync-flow.md) — flujos, tablas de sync, seguridad, troubleshooting.

## Especificaciones

- [sync-config spec](openspec/specs/sync-config/spec.md) — Seed/merge de `opencode-synced`
- [vps-quickstart spec](openspec/specs/vps-quickstart/spec.md) — Bootstrap en VPS
- [runtime-config spec](openspec/specs/runtime-config/spec.md) — Variables de entorno y entrypoint

## Estructura

```text
.
├── docker-compose.yml    # Servicio OpenChamber
├── Dockerfile            # Construcción de imagen
├── entrypoint.sh         # Seed/merge de configuración
├── scripts/              # Scripts de inicialización
├── data/                 # Directorio de datos (runtime)
├── openspec/             # Especificaciones técnicas
└── docs/                 # Guías de usuario
```
