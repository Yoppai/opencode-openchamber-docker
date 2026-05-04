# Política de Actualización

Guía de versionado, tags y automatización de dependencias para `opencode-openchamber-docker`.

---

## 1. latest vs pinned

Las imágenes se publican en GHCR (`ghcr.io/yoppai/opencode-openchamber`) con múltiples tags.

| Tag | Propósito | Recomendación |
|-----|-----------|---------------|
| `latest` | Último build de main. Conveniencia, desarrollo rápido. | ❌ No para producción |
| `openchamber-X-opencode-Y` | Versiones fijas de ambos componentes. Reproducibilidad total. | ✅ Producción |
| `main` | Último commit en rama main. Preview de desarrollo. | ❌ Solo pruebas |
| `sha-XXXXXXX` | Commit específico. Trazabilidad directa a fuente. | 🔍 Debug/forense |

**Regla general:** `latest` prioriza conveniencia sobre reproducibilidad.
Para entornos productivos críticos, siempre usa un tag pinned.

---

## 2. Tags pinned: formato `openchamber-X-opencode-Y`

```text
openchamber-1.2.3-opencode-4.5.6
│            │       │         │
│            │       │         └── versión de opencode-ai (npm)
│            │       └──────────── separador
│            └─────────────────── versión de @openchamber/web (npm)
└──────────────────────────────── prefijo
```

Este tag garantiza que el build usa versiones exactas de ambos paquetes npm:
- `@openchamber/web` en versión `1.2.3`
- `opencode-ai` en versión `4.5.6`

Cualquier persona que haga pull de este tag obtiene **exactamente el mismo software**,
independientemente de cuándo lo haga.

---

## 3. Actualización manual: `workflow_dispatch`

El workflow [publish.yml](../.github/workflows/publish.yml) soporta
`workflow_dispatch` con dos inputs opcionales:

| Input | Default | Descripción |
|-------|---------|-------------|
| `OPENCHAMBER_VERSION` | `latest` | Versión npm de `@openchamber/web` |
| `OPENCODE_VERSION` | `latest` | Versión npm de `opencode-ai` |

**Cómo usarlo:**

1. Ir a GitHub → Actions → "Publish GHCR Multi-Arch"
2. Clic "Run workflow"
3. Ingresar versiones deseadas (ej. `1.2.3` y `4.5.6`)
4. Ejecutar

El build produce un tag pinned `openchamber-1.2.3-opencode-4.5.6` además de `latest` y `sha-*`.

> [!TIP]
> Si no especificas versiones, ambas usan `latest` (lo último publicado en npm).

---

## 4. Dependabot

El repositorio incluye [`.github/dependabot.yml`](../.github/dependabot.yml)
para actualizaciones automáticas de dependencias de infraestructura.

### Alcance

Dependabot **solo** monitorea:

| Ecosistema | ¿Qué actualiza? |
|------------|-----------------|
| `github-actions` | Workflows de CI/CD (actions/checkout, docker/*, etc.) |
| `docker` | Imagen base en `FROM node:22-bookworm-slim` |

Dependabot **no** modifica dependencias de runtime de la aplicación
(paquetes npm de OpenChamber/OpenCode). Esas se gestionan via
`workflow_dispatch` o Renovate (futuro).

### Configuración

- Intervalo: **semanal**
- Labels: `dependencies` en todos los PRs
- Límite: máximo **5 PRs abiertos** simultáneamente
- Sin auto-merge: todo PR requiere aprobación manual

### Sin auto-merge

Dependabot genera PRs, pero **nunca** se mergean automáticamente.
Cada PR requiere revisión humana antes del merge. Esto aplica tanto
a PRs de Dependabot como a cualquier workflow del repositorio.

---

## 5. Renovate (opción futura)

[Renovate](https://docs.renovatebot.com/) es una alternativa más configurable
a Dependabot. No está implementada en este cambio, pero se documenta como
opción futura si se necesita:

- Agrupación personalizada de PRs
- Schedule más granular
- Automatización avanzada de estrategias de merge
- Soporte para más ecosistemas

Si en el futuro se adopta Renovate, Dependabot debería desactivarse
para evitar duplicación.

---

## 6. Resumen: qué tag usar según entorno

| Entorno | Tag recomendado | Razón |
|---------|-----------------|-------|
| Desarrollo local | `latest` | Flexibilidad, último código |
| Staging/QA | `openchamber-X-opencode-Y` | Reproducibilidad entre tests |
| Producción | `openchamber-X-opencode-Y` | Versión conocida y estable |
| Forense/Debug | `sha-XXXXXXX` | Trazabilidad exacta al commit |

> [!IMPORTANT]
> Cambiar de `latest` a un tag pinned requiere modificar la imagen en
> `docker-compose.yml`. Ver [quickstart](../README.md#quickstart).
