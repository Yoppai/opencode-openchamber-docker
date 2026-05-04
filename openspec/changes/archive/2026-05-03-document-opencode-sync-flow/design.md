# Design: Documentar Flujo opencode-synced

## Technical Approach

Crear documentación de usuario en dos archivos Markdown: `README.md` raíz como quick reference, y `docs/sync-flow.md` como guía completa del flujo `/sync-init` → `/sync-link`. Ambos referencian specs técnicos existentes mediante rutas relativas. Todo en español MX, formato GitHub Flavored Markdown.

## Architecture Decisions

### Decision: Document file layout

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Monofile README | Fácil de encontrar, pero crece indefinidamente con cada feature | Rejected |
| README + `docs/` | Root breve, detalle escala en directorio dedicado, alinea con estándar OSS | **Selected** |

**Rationale**: No existe `README.md` raíz. Separar evita un monolito de texto y permite que `sync-flow.md` evolucione independientemente.

### Decision: Sync flow doc structure

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Narrativa continua | Difícil saltar a sección específica | Rejected |
| Secciones numeradas con anclas | Escaneable, permite deep-link desde README o issues | **Selected** |

Secciones de `docs/sync-flow.md`:
1. Overview — qué es opencode-synced y objetivo.
2. Prerequisites — gh auth, repo privado.
3. Flujo local (`/sync-init`) — paso a paso con comandos.
4. Flujo VPS (`/sync-link <repo>`) — paso a paso con comandos.
5. Tabla sync/no-sync — columnas: Categoría, Sync por default, Notas.
6. Seguridad — `includeSecrets`, `includeSessions`, multi-auth stores.
7. Volumen vs Git sync — tabla comparativa.
8. Sesiones multi-máquina (Turso).
9. Troubleshooting — problemas comunes + soluciones.

### Decision: Warning/security pattern

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Texto bold/rojo manual | No renderiza consistente en todos los viewers | Rejected |
| GFM alerts (`> [!WARNING]`, `> [!CAUTION]`) | Nativo en GitHub, destacado semántico, portable | **Selected** |

Uso:
- `[!CAUTION]` para `/sync-link` overwrite y exposición de `GH_TOKEN`.
- `[!WARNING]` para `includeSecrets`, riesgo de conflicto en sesiones.

### Decision: Table format for sync scope

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Listas con emojis | Escaneable pero desalineado en diff | Rejected |
| Tabla Markdown 3-columnas | Compacta, alinea con proposal, fácil de mantener | **Selected** |

Columnas: `Categoría`, `Sync por default`, `Notas`. Notas explican razón de seguridad cuando aplica.

### Decision: Code block conventions

| Option | Tradeoff | Decision |
|--------|----------|----------|
| ` ```text ` sin prefijo | Pierde syntax highlight, no distingue input/output | Rejected |
| ` ```bash ` con prefijo `$` | Highlight de shell, indica comando vs output, copiable fácil | **Selected** |

Notas de plataforma (Linux/macOS/Windows Git Bash) se añaden como comentarios `#` dentro del bloque o línea previa.

### Decision: Cross-linking strategy

| Option | Tradeoff | Decision |
|--------|----------|----------|
| URLs absolutas a GitHub | Rotan si cambia rama, no funcionan offline | Rejected |
| Rutas relativas Markdown (`./docs/sync-flow.md`) | Estables en repo, funcionan en checkout local y GitHub | **Selected** |

Enlaces:
- `README.md` → `docs/sync-flow.md`
- `docs/sync-flow.md` → `openspec/specs/sync-config/spec.md` y `openspec/specs/vps-quickstart/spec.md`

### Decision: Language and tone

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Inglés técnico | Mayor alcance, pero usuario target habla español | Rejected |
| Español MX, técnico y directo | Alinea con `AGENTS.md` y PRD original, claridad para usuario local | **Selected** |

Reglas de estilo: sin artículos de relleno, fragmentos aceptables, sustantivo + verbo + razón.

## Data Flow

No aplica — documentación estática. Flujo del lector:

    README.md ──→ docs/sync-flow.md ──→ specs técnicos (opcional)
         │
         └──────→ docker-compose.yml / .env.example (runtime)

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `README.md` | Create | Quick ref de sync, badge/link a `docs/sync-flow.md`, link a specs y quickstart |
| `docs/sync-flow.md` | Create | Guía completa: flujos, tablas, seguridad, troubleshooting |

## Interfaces / Contracts

N/A. No hay código ni APIs nuevas. Contrato implícito: convención Markdown GFM, español MX.

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Docs review | Links rotos, typos, formato GFM | `markdownlint` + revisión manual de rutas relativas |
| Smoke test | Comandos shell copiables ejecutan sin error | Validación manual en shell local |

## Migration / Rollout

No migration required.

## Open Questions

None.
