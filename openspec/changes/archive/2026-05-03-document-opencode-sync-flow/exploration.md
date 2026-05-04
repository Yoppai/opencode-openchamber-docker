## Exploration: document-opencode-sync-flow (ch-05)

### Current State

Sync configuration mechanics están implementados pero sin documentación de usuario:

1. **Seed/Merge (`entrypoint.sh`)**: Bash script con `jq` que crea `opencode.jsonc` con `plugin: ["opencode-synced"]` si no existe config, o inyecta el plugin si falta. Usa backup/restore safety. JSONC comments se pierden en modificación (tradeoff documentado en código).

2. **Persistencia (`docker-compose.yml`)**: 2 bind mounts — `data/home → /home/openchamber` (todo el home), `workspaces → /home/openchamber/workspaces` (código fuente separado). Plugins, auth, SSH, agents persisten automáticamente.

3. **Dependencias sync**: `gh`, `git`, `jq` instalados en imagen. `GH_TOKEN` en `.env.example` para auth headless.

4. **Especificaciones existentes**:
   - `openspec/specs/sync-config/spec.md` — solo define seed/merge behavior del entrypoint
   - `openspec/specs/vps-quickstart/spec.md` — solo define bootstrap flow (cp .env, init-dirs, compose up)
   - Ambos son specs de comportamiento técnico, NO documentación de usuario

### Documentation Gaps

| Gap | PRD Reference | Severity |
|-----|---------------|----------|
| No existe README.md ni docs de usuario en project root | — | CRITICAL |
| No hay docs del flujo `/sync-init` local → `/sync-link` VPS | §306-313 | HIGH |
| No hay docs de qué sincroniza vs qué NO (table) | §176-193 | HIGH |
| No hay docs de seguridad: `includeSecrets`, `includeSessions`, `includePromptStash` defaults | §341-349 | HIGH |
| No hay docs de stores multi-auth sensibles y `extraSecretPaths` | §224-238 | HIGH |
| No hay docs de Turso como recomendación para sesiones multi-máquina | §217-223 | MEDIUM |
| No hay docs de diferencia entre persistencia local (volumen) vs sync Git | §358-359 | MEDIUM |
| `openspec/specs/sync-config/README.md` dice "no spec.md yet" pero sí existe (stale) | — | LOW |

### PRD Requirements vs Implemented

| Requirement | Implemented | Doc Needed |
|-------------|-------------|------------|
| Seed/merge de `opencode-synced` en entrypoint | ✅ `entrypoint.sh` | ✅ Explicar que el contenedor viene con plugin habilitado |
| `gh` + `git` en imagen (requisito sync) | ✅ `Dockerfile` L26-27 | ✅ Explicar requisito y GH_TOKEN |
| Persistencia vía volúmenes | ✅ `docker-compose.yml` | ✅ Explicar diferencia con sync Git |
| `includeSecrets: false` por default | ⚠️ No en código (es default de opencode-synced) | ✅ Documentar que es default seguro |
| `includeSessions: false` por default | ⚠️ No en código (es default de opencode-synced) | ✅ Documentar + Turso alternativa |
| Flujo `/sync-init` → `/sync-link` | ⚠️ Son comandos built-in de OpenCode | ✅ Documentar paso a paso |
| Advertencias de seguridad multi-auth stores | ❌ No implementado | ✅ Documentar opt-in explícito + repo privado |
| Diferencia volumen vs git sync | ❌ No documentado | ✅ Documentar |

### Existing Files Overlap

- `entrypoint.sh` — contiene la lógica seed/merge real (líneas 10-58)
- `Dockerfile` — instalación de `gh`, `git`, `jq` (líneas 18-29)
- `docker-compose.yml` — volúmenes, healthcheck, env_file
- `.env.example` — `GH_TOKEN` documentado, build args NOTA (líneas 87-96)
- `openspec/specs/sync-config/spec.md` — behavior spec, no user doc
- `openspec/specs/vps-quickstart/spec.md` — bootstrap spec, no user doc
- `openspec/PRD.md` — fuente de requisitos detallados

### Key Technical Decisions to Document

1. **Qué sincroniza por default**: config OpeNCode (`opencode.jsonc`), plugins, skills, agents, themes/modes/tools, model favorites
2. **Qué NO sincroniza por default**: secrets, MCP secrets, sessions, prompt stash, stores multi-auth, configuración OpenChamber
3. **`includeSecrets: false`** — default seguro; activar solo con repo privado
4. **`includeSessions: false`** — default seguro; sesiones por Git = riesgo de conflicto
5. **`includePromptStash: false`** — default seguro
6. **Multi-auth stores** (~/.config/opencode-multi-auth/accounts.json, etc.) — contienen tokens OAuth; solo sincronizar con `extraSecretPaths` + repo privado + entendimiento de riesgo
7. **Turso > Git para sesiones multi-máquina** — recomendar `/sync-sessions-backend turso` + `/sync-sessions-setup-turso`
8. **Persistencia local por volumen ≠ sync Git** — volúmenes preservan datos en ese VPS; sync replica config local a través de máquinas
9. **`/sync-link` puede sobrescribir config local** — documentar warning antes de usar
10. **JSONC comments se pierden** si entrypoint modifica config existente (tradeoff conocido)

### Recommended Scope for ch-05

Crear documentación de usuario para el flujo de sincronización. NO código nuevo.

**Documentos a crear:**

1. **`docs/sync-flow.md`** — Documento principal explicando:
   - Arquitectura: local → GitHub private repo → VPS
   - Prerequisitos: `gh` auth, GitHub token, repo privado
   - Flujo paso a paso: `/sync-init` en máquina local
   - Flujo paso a paso: `/sync-link <repo>` en VPS
   - Tabla qué sync / qué no
   - Seguridad: secrets, sessions, multi-auth stores
   - Turso para sesiones multi-máquina activas
   - Diferencia volumen local vs sync Git

2. **`README.md`** (proyecto root) — Referencia rápida con enlace a `docs/sync-flow.md` y bootstrap flow

3. **Update `openspec/specs/sync-config/README.md`** — Corregir estado stale ("spec.md exists now")

**Specs a actualizar:**

4. **`openspec/specs/sync-config/spec.md`** — Agregar requirements de documentación (lo que debe explicarse)
5. **`openspec/specs/vps-quickstart/spec.md`** — Extender para cubrir sync después de bootstrap

### Risks & Gotchas

| Risk | Detail |
|------|--------|
| `/sync-link` sobrescribe config | Documentar warning de que puede reemplazar config local del VPS |
| Multi-auth tokens en Git | Riesgo de filtración; documentar que solo repo privado + opt-in explícito |
| Sesiones Git conflict | Documentar Turso como alternativa recomendada |
| JSONC comments perdidos | Entrypoint usa sed para quitar // comments antes de jq merge |
| `GH_TOKEN` expuesto en .env | `.gitignore` excluye .env, pero documentar no comitear .env |
| Usuario confunde volumen con sync | Documentar claramente: volumen = persiste en esa máquina, sync = replica entre máquinas |
| SSH permissions incorrectos | Entrypoint corrige con chmod 700 + warning |

### Ready for Proposal

Yes. Scope claro: solo documentación + specs update, sin cambios de código.
Dependencias: ch-04 archivado ✅, entrypoint/sh implementado ✅, docker-compose funcionando ✅.
