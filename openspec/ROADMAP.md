# Roadmap OpenSpec: Dockerizar OpenCode + OpenChamber

> **Roadmap v0.8** | Última actualización: 2026-05-03  
> Basado en `openspec/PRD.md`.  
> Cada change debe ser verificable de forma aislada o con sus dependencias completadas.
> ch-00 archivado. ch-01 archivado. ch-02 archivado. ch-03 archivado.

---

## Changelog del Roadmap

| Versión | Fecha | Cambio |
| :--- | :--- | :--- |
| v0.8 | 2026-05-03 | ch-02 archivado como build-container-image; delta spec container-image sync; ROADMAP actualizado |
| v0.7 | 2026-05-03 | ch-03 archivado; delta specs runtime-config + sync-config sync a main specs; ROADMAP actualizado |
| v0.6 | 2026-05-03 | ch-01 archivado como spike/discovery; delta spec NO sync (validation-only); ROADMAP actualizado |
| v0.5 | 2026-05-03 | ch-00 archivado; delta spec sync a main specs; ROADMAP actualizado |
| v0.4 | 2026-05-03 | ch-00 formalizado y activo; registry de specs candidatos creado; trazabilidad PRD→artifacts alineada |
| v0.3 | 2026-05-03 | Arquitectura de roadmap aplicada: changelog, completados, fases tabulares, notas técnicas, grafo de dependencias, estado de specs, criterios por fase e inventario de gaps críticos |
| v0.2 | 2026-05-03 | Roadmap convertido a índice OpenSpec con slices archivables, spec domains, gates y anti-patrones |
| v0.1 | 2026-05-03 | Roadmap inicial F0-F5 basado en PRD |

---

## Propósito

Este archivo es un **índice de coordinación** para convertir el PRD en cambios OpenSpec archivables.

No reemplaza los artifacts formales de OpenSpec. La fuente de verdad evolutiva vive en:

```txt
openspec/changes/<change>/
├── proposal.md       # why + scope
├── specs/**/spec.md  # what: comportamiento verificable
├── design.md         # how: decisiones técnicas
└── tasks.md          # pasos implementables
```

Cuando un cambio termina, `openspec archive <change>` debe fusionar sus delta specs hacia `openspec/specs/`.

---

## Completados

| ID | Nombre | Spec | Archivado |
| :--- | :--- | :--- | :--- |
| `ch-00` | `formalize-docker-roadmap` | `spec-domain-registry` | ✅ `openspec/changes/archive/2026-05-03-formalize-docker-roadmap/` |
| `ch-01` | `spike-openchamber-npm-runtime` | `runtime-validation` (validation-only, NO sync) | ✅ `openspec/changes/archive/2026-05-03-spike-openchamber-npm-runtime/` |
| `ch-02` | `build-container-image` | `container-image` (delta sync) | ✅ `openspec/changes/archive/2026-05-03-build-container-image/` |
| `ch-03` | `add-runtime-entrypoint` | `runtime-config` (delta sync), `sync-config` (NEW) | ✅ `openspec/changes/archive/2026-05-03-add-runtime-entrypoint/` |

---

## Modelo de conversión PRD → OpenSpec

```txt
openspec/PRD.md
   │
   │ extraer objetivos, non-goals, requisitos, riesgos, acceptance criteria
   ▼
openspec/roadmap.md
   │
   │ dividir en slices archivables
   ▼
openspec/changes/<slice>/
   ├─ proposal.md
   ├─ specs/**/spec.md
   ├─ design.md
   └─ tasks.md
   │
   │ apply → verify → archive
   ▼
openspec/specs/
   └─ source of truth del comportamiento actual
```

## Regla de separación

| Fuente PRD | Artifact OpenSpec |
| :--- | :--- |
| Problema / objetivos | `proposal.md` Intent |
| Alcance / non-goals | `proposal.md` Scope / Non-goals |
| Requisitos funcionales | `specs/**/spec.md` |
| Requisitos no funcionales | `specs/**/spec.md` + `design.md` |
| Decisiones acordadas | `design.md` Architecture Decisions |
| Riesgos y mitigaciones | `design.md` Risks / Mitigations |
| Criterios de aceptación | `tasks.md` + verify checklist |

Specs describen comportamiento observable. Detalles como `node:22-bookworm-slim`, `npm install -g`, Buildx o `tini` viven en `design.md` o `tasks.md`, salvo cuando son contrato explícito del producto.

---

## Definición MVP

```txt
MVP = ch-01 + ch-02 + ch-03 + ch-04 + ch-05 + ch-06
Release productivo = MVP + ch-07
```

MVP significa:

- Imagen multi-arch publicada en GHCR.
- OpenChamber arranca y protege UI con password cuando aplica.
- OpenCode disponible dentro del contenedor.
- `opencode-synced` habilitado sin borrar config existente.
- Compose persiste config, state, cache, auth, SSH y workspaces.
- Docs explican sync, secrets, sessions y volúmenes.

---

## Fase 0: Formalización OpenSpec

> Objetivo: convertir PRD y roadmap en plan OpenSpec trazable.  
> **MVP: No**

| ID del Cambio | Nombre de la Tarea | Estado | Dependencias | Spec | Referencia al PRD |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `ch-00` | `formalize-docker-roadmap`: crear change formal, specs candidatas y mapping PRD → artifacts | ✅ Archivado | `openspec/PRD.md`, `openspec/changes/archive/2026-05-03-formalize-docker-roadmap/` | 🟢 Especificado (`spec-domain-registry`) | §19-29 Objetivos, §502-513 Criterios de aceptación |

**Notas técnicas Fase 0:**
- ch-00 archivado en `openspec/changes/archive/2026-05-03-formalize-docker-roadmap/`.
- `openspec/specs/spec-domain-registry/spec.md` es ahora main spec (delta sync).
- `openspec/specs/` contiene registry placeholder por dominio; behavior specs pendientes para ch-01..ch-07.
- `openspec/roadmap.md` es coordinación, no source of truth.
- `openspec/config.yaml` usa schema `spec-driven` con artifacts `proposal`, `specs`, `design`, `tasks`.
- Próximo paso recomendado: `ch-01 spike-openchamber-npm-runtime`.

---

## Fase 1: Spike y Runtime de Imagen

> Objetivo: validar `@openchamber/web` y construir imagen mínima con OpenCode + OpenChamber.  
> **MVP: Sí** | **Bloqueante: `ch-01` valida supuestos npm/flags/ARM antes de invertir en CI**

| ID del Cambio | Nombre de la Tarea | Estado | Dependencias | Spec | Referencia al PRD |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `ch-01` | `spike-openchamber-npm-runtime`: validar binario `openchamber`, `serve`, `--ui-password` y riesgos ARM | ✅ Archivado (NO-GO ch-02: opencode missing) | `ch-00` | 🟢 Validation-only (NO sync) | §101-133 OpenChamber, §482-496 Riesgos |
| `ch-02` | `build-container-image`: imagen local con Node 22 Debian/glibc, OpenCode, OpenChamber, Bun, gh, git, SSH, tini y usuario no-root | ✅ Archivado | `ch-01` | 🟢 Especificado (`container-image`) | §43-68 Stack e Imagen, §69-100 Orden de instalación |
| `ch-03` | `add-runtime-entrypoint`: entrypoint con password, warning sin password y seed/merge de `opencode-synced` | ✅ Archivado | `ch-02` | 🟢 Especificado (`runtime-config`, `sync-config`) | §124-130 UI password, §167-208 OpenCode/opencode-synced, §240-246 Acceso |

**Notas técnicas Fase 1:**
- `ch-01`: ✅ Archivado. Hallazgo crítico: `openchamber serve` requiere `opencode` CLI en PATH. Todos los flags CLI confirmados. Prebuilds AMD64/ARM64 OK.
- `ch-02`: ✅ Archivado. Imagen single-stage `node:22-bookworm-slim`. Tradeoff ~50-100MB extra vs multi-stage, evita breakage de módulos nativos. TARGETARCH para Bun. Usuario no-root `openchamber` UID/GID 1000.
- `ch-03`: ✅ Archivado. seed/merge preserva config existente, evita duplicar `opencode-synced`.
- `OPENCHAMBER_VERSION` y `OPENCODE_VERSION` son build args, no runtime vars.

---

## Fase 2: Compose, Persistencia y Sync

> Objetivo: experiencia local/VPS reproducible, persistente y segura por default.  
> **MVP: Sí**

| ID del Cambio | Nombre de la Tarea | Estado | Dependencias | Spec | Referencia al PRD |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `ch-04` | `add-compose-persistence`: `docker-compose.yml`, `.env.example`, init dirs y volúmenes persistentes | ⏳ Pending | `ch-03` | ❌ Pendiente (`persistence`, `runtime-config`, `vps-quickstart`) | §288-324 Bootstrap/Persistencia, §325-338 Matriz de volúmenes |
| `ch-05` | `document-opencode-sync-flow`: docs `/sync-init`, `/sync-link`, secrets, sessions, Turso y diferencia volúmenes vs sync Git | ⏳ Pending | `ch-04` | ❌ Pendiente (`sync-config`, `vps-quickstart`) | §176-239 opencode-synced y stores sensibles, §306-313 Sincronización, §341-349 Seguridad |

**Notas técnicas Fase 2:**
- `ch-04`: volúmenes deben cubrir OpenChamber, OpenCode config/share/state/cache, agents, gh, ssh, multi-auth y workspaces.
- `ch-05`: `opencode-synced` no debe presentarse como backup completo de `$HOME`.
- `ch-05`: stores multi-auth pueden contener tokens; sólo deben sincronizarse con opt-in explícito y repo privado.
- Sessions por Git son riesgo de conflicto; Turso debe quedar como recomendación si usuario quiere sesiones multi-máquina activas.

---

## Fase 3: Publicación GHCR Multi-Arch

> Objetivo: publicar imagen usable desde VPS `linux/amd64` y `linux/arm64`.  
> **MVP: Sí**

| ID del Cambio | Nombre de la Tarea | Estado | Dependencias | Spec | Referencia al PRD |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `ch-06` | `publish-ghcr-multiarch`: GitHub Actions, Buildx, QEMU, GHCR, tags mínimos, workflow dispatch y manifest inspect | ⏳ Pending | `ch-02` (`ch-03` recomendado antes de release) | ❌ Pendiente (`ghcr-publishing`, `container-image`) | §361-390 CI/CD esperado, §392-423 Política de actualización y pins |

**Notas técnicas Fase 3:**
- `ch-06` puede avanzar después de `ch-02`, pero no debe considerarse releaseable hasta que `ch-03` esté estable.
- Tags mínimos MVP: `latest`, `main`, `sha-<shortsha>`, `openchamber-<version>-opencode-<version>`.
- `workflow_dispatch` debe aceptar overrides de `OPENCHAMBER_VERSION` y `OPENCODE_VERSION`.
- CI debe validar manifest multi-arch después del push.

---

## Fase 4: Release Hardening y Documentación Productiva

> Objetivo: dejar experiencia productiva entendible para usuarios nuevos.  
> **MVP: No**

| ID del Cambio | Nombre de la Tarea | Estado | Dependencias | Spec | Referencia al PRD |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `ch-07` | `add-production-docs-and-update-policy`: README quickstart, pins exactos, updates, Dependabot, Renovate futuro y troubleshooting | ⏳ Pending | `ch-01`-`ch-06` | ❌ Pendiente (`vps-quickstart`, `ghcr-publishing`, `sync-config`) | §392-423 Política de actualización/pins, §482-496 Riesgos, §502-513 Criterios de aceptación |

**Notas técnicas Fase 4:**
- Docs deben explicar `latest` como comodidad, no reproducibilidad.
- Docs deben recomendar `UI_PASSWORD` fuerte para cloud.
- Docs deben explicar que reverse proxy/TLS no es alcance opinionado MVP.
- Dependabot puede cubrir Actions, Docker base images y security alerts; Renovate queda opcional futuro.

---

## Grafo de Dependencias

```txt
Fase 0
  ch-00

Fase 1
  ch-00 ──→ ch-01 ──→ ch-02 ──→ ch-03

Fase 2
  ch-03 ──→ ch-04 ──→ ch-05

Fase 3
  ch-02 ──→ ch-06
             ▲
             └── ch-03 recomendado antes de release final

Fase 4
  ch-01 ─┬─→ ch-07
  ch-02 ─┤
  ch-03 ─┤
  ch-04 ─┤
  ch-05 ─┤
  ch-06 ─┘
```

**Dependencia crítica no visualizada por fase:**

```txt
ch-01 (spike OpenChamber npm runtime) es prerequisito técnico para:
  ch-02, ch-03, ch-04, ch-06, ch-07

Sin ch-01, se puede construir infraestructura alrededor de flags/binarios falsos.
```

---

## Estado de Specs

| Spec | Change Relacionado | Estado |
| :--- | :--- | :--- |
| `container-image` | `ch-02`, `ch-06` | 🟢 Especificado |
| `runtime-config` | `ch-02`, `ch-03`, `ch-04` | 🟢 Especificado |
| `runtime-validation` | `ch-01` | 🔵 Validation-only (NO sync: spike, failed scenarios) |
| `persistence` | `ch-04` | 🟡 Registrado |
| `sync-config` | `ch-03`, `ch-05`, `ch-07` | 🟢 Especificado |
| `ghcr-publishing` | `ch-06`, `ch-07` | 🟡 Registrado |
| `vps-quickstart` | `ch-04`, `ch-05`, `ch-07` | 🟡 Registrado |

---

## Criterios de Aceptación por Fase

### Fase 0

- [x] `ch-00`: **DADO** `openspec/PRD.md`, **CUANDO** se crea el change formal, **ENTONCES** cada criterio de aceptación del PRD queda mapeado a spec, design o task.
- [x] `ch-00`: **DADO** roadmap actualizado, **CUANDO** se revisa, **ENTONCES** muestra changes, dependencias, specs candidatas, gates, notas técnicas y gaps.

### Fase 1

- [x] `ch-01`: **DADO** paquete `@openchamber/web`, **CUANDO** se instala desde npm, **ENTONCES** el binario `openchamber` existe y `openchamber serve` falla sin `opencode` CLI (spike descubrió blocker crítico).
- [x] `ch-01`: **DADO** OpenChamber instalado, **CUANDO** se valida password UI, **ENTONCES** se documenta que `--ui-password` y `OPENCHAMBER_UI_PASSWORD` son parseados pero no verificables sin `opencode`.
- [x] `ch-02`: **DADO** Dockerfile de imagen, **CUANDO** se construye localmente, **ENTONCES** `opencode`, `openchamber`, `bun`, `gh`, `git`, `ssh` y `tini` están disponibles.
- [x] `ch-02`: **DADO** contenedor iniciado, **CUANDO** se inspecciona proceso/runtime, **ENTONCES** corre con usuario `openchamber` no-root UID/GID 1000.
- [x] `ch-03`: **DADO** `UI_PASSWORD` configurado, **CUANDO** arranca el contenedor, **ENTONCES** OpenChamber recibe password UI.
- [x] `ch-03`: **DADO** `UI_PASSWORD` vacío, **CUANDO** arranca el contenedor, **ENTONCES** logs muestran warning visible y el proceso continúa.
- [x] `ch-03`: **DADO** config OpenCode existente, **CUANDO** corre seed/merge, **ENTONCES** `opencode-synced` aparece una sola vez en `plugin[]` sin borrar otros campos.

### Fase 2

- [ ] `ch-04`: **DADO** `.env.example`, **CUANDO** usuario lo copia a `.env` y corre init dirs, **ENTONCES** todos los paths persistentes requeridos existen.
- [ ] `ch-04`: **DADO** `docker compose up -d openchamber`, **CUANDO** el contenedor se recrea, **ENTONCES** config/state/cache/gh/ssh/agents/workspaces persisten.
- [ ] `ch-05`: **DADO** docs de sync, **CUANDO** usuario sigue flujo local `/sync-init` y VPS `/sync-link <repo>`, **ENTONCES** entiende que config/plugins/skills/agents sincronizan pero secrets/sessions no por default.
- [ ] `ch-05`: **DADO** stores multi-auth sensibles, **CUANDO** docs los mencionan, **ENTONCES** recomiendan persistencia local por volumen y opt-in explícito para sync privado.

### Fase 3

- [ ] `ch-06`: **DADO** push a `main` o `workflow_dispatch`, **CUANDO** CI corre, **ENTONCES** publica `ghcr.io/<owner>/opencode-openchamber`.
- [ ] `ch-06`: **DADO** imagen publicada, **CUANDO** se inspecciona manifest, **ENTONCES** contiene `linux/amd64` y `linux/arm64`.
- [ ] `ch-06`: **DADO** versión exacta de OpenChamber/OpenCode, **CUANDO** se publica imagen pinned, **ENTONCES** existe tag `openchamber-<version>-opencode-<version>`.

### Fase 4

- [ ] `ch-07`: **DADO** usuario nuevo con VPS, **CUANDO** sigue README, **ENTONCES** puede levantar OpenChamber con compose sin contexto externo.
- [ ] `ch-07`: **DADO** despliegue productivo, **CUANDO** lee docs, **ENTONCES** entiende `latest` vs pins exactos, password fuerte, límites de sync, secrets y sessions.
- [ ] `ch-07`: **DADO** problema común de GH auth, SSH, sync overwrite, ARM deps o password vacío, **CUANDO** consulta troubleshooting, **ENTONCES** encuentra mitigación accionable.

---

## Inventario de Gaps Críticos

| # | Gap | Impacto | Change Relacionado |
| :--- | :--- | :--- | :--- |
| 1 | ~~**ch-00 ya está activo, pero no archivado**~~ | ~~Roadmap aún no tiene spec archivada; sólo registry y trazabilidad~~ | 🟢 Resuelto: ch-00 archivado |
| 2 | **No hay behavior specs escritos** | Acceptance criteria aún no son source of truth verificable | `ch-00`, todos |
| 3 | ~~**`@openchamber/web` runtime no validado**~~ | ~~Se puede construir imagen/CI sobre binario o flags incorrectos~~ | 🟢 Resuelto: ch-01 archivado |
| 4 | **Multi-arch ARM no probado a nivel CI** | ch-02 soporta TARGETARCH para Bun; falta build multi-arch automatizado en CI | `ch-06` |
| 5 | ~~**Seed/merge JSONC no diseñado formalmente**~~ | ~~Riesgo de borrar config de usuario o duplicar plugin~~ | 🟢 Resuelto: ch-03 archivado |
| 6 | **Secrets/sessions podrían confundirse con sync config** | Riesgo de filtración o conflictos Git | `ch-05`, `ch-07` |
| 7 | **GHCR owner/tag policy no fijada en repo** | Publicación puede quedar inconsistente | `ch-06` |

---

## Orden recomendado

```txt
1. ch-00 formalize-docker-roadmap
2. ch-01 spike-openchamber-npm-runtime
3. ch-02 build-container-image
4. ch-03 add-runtime-entrypoint
5. ch-04 add-compose-persistence
6. ch-05 document-opencode-sync-flow
7. ch-06 publish-ghcr-multiarch
8. ch-07 add-production-docs-and-update-policy
```

`ch-06` puede avanzar en paralelo después de `ch-02`, pero su gate final depende de que imagen y entrypoint estén suficientemente estables.

---

## Anti-patrones a evitar

- Hacer un solo mega-change para todo el PRD.
- Meter detalles de Dockerfile o CI dentro de specs behavior-first.
- Tratar `roadmap.md` como source of truth final.
- Archivar sin verify cuando hay cambios en specs.
- Sincronizar secrets/sessions por default.
- Invertir en CI multi-arch antes de validar `@openchamber/web` npm runtime.

---

## Próximo paso sugerido

ch-02, ch-03 archivados. Siguiente change en orden recomendado:

```txt
ch-04 add-compose-persistence
```

O paso a paso:

```txt
/opsx:new add-compose-persistence
/opsx:continue
```
