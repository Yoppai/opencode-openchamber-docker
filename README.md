# OpenChamber Docker

Despliegue containerizado de OpenChamber + OpenCode con Docker Compose.

---

## Quickstart

Guía paso a paso para levantar OpenChamber en un VPS o servidor propio.
Sin dependencia de documentación externa.

### Prerrequisitos

- **Docker** y **Docker Compose** instalados ([docs](https://docs.docker.com/engine/install/))
- **Git** para clonar el repositorio
- Acceso a **GitHub Container Registry** (pull público, sin auth requerida)
- **Arquitectura:** `linux/amd64` o `linux/arm64` (Apple Silicon, Raspberry Pi)

### 1. Clonar repositorio

```bash
$ git clone https://github.com/yoppai/opencode-openchamber-docker.git
$ cd opencode-openchamber-docker
```

### 2. Configurar variables de entorno

```bash
$ cp .env.example .env
```

Editar `.env` con tus preferencias. Mínimo recomendado:

```bash
# Puerto de exposición (default: 3000)
OPENCHAMBER_PORT=3000

# Contraseña UI — OBLIGATORIO para entornos cloud
UI_PASSWORD=tu_contraseña_segura_aqui
```

> [!IMPORTANT]
> `UI_PASSWORD` vacío inicia OpenChamber **sin protección**.
> Para cloud/VPS, usa una contraseña fuerte (mín. 16 caracteres).
> Ver [guía de troubleshooting](docs/troubleshooting.md#4-ui_password-vacío).

### 3. Inicializar directorios de volumen

```bash
$ mkdir -p data/home workspaces
```

Crea los directorios locales para volúmenes Docker (`./data/`, `./workspaces/`).
Si no ejecutas este paso, `docker compose up` falla con `no such file or directory`.

### 4. Iniciar contenedor

```bash
$ docker compose up -d openchamber
```

El contenedor arranca en background (`-d`). Verifica el estado:

```bash
$ docker compose ps
$ docker compose logs openchamber
```

### 5. Acceder a la UI

```
http://<tu-vps-ip>:3000
```

Si configuraste `UI_PASSWORD`, ingrésala al cargar la UI por primera vez.

### Siguientes pasos

- [Política de actualización](docs/update-policy.md) — latest vs pinned, tags, Dependabot
- [Guía de troubleshooting](docs/troubleshooting.md) — problemas comunes y soluciones

### Sobre latest vs pinned

El `docker compose up` default usa la imagen `latest`.
Para entornos productivos se recomienda un tag pinned:

```yaml
# docker-compose.yml — cambiar image:
image: ghcr.io/yoppai/opencode-openchamber:openchamber-1.2.3-opencode-4.5.6
```

Ver [política de actualización](docs/update-policy.md) para más detalle.

---

## Estructura

```text
.
├── docker-compose.yml    # Servicio OpenChamber
├── Dockerfile            # Construcción de imagen
├── entrypoint.sh         # Configuración de entorno y arranque
├── data/                 # Directorio de datos (runtime)
└── docs/                 # Guías de usuario
│   ├── update-policy.md  # Política de actualización
│   └── troubleshooting.md# Guía de problemas comunes
```
