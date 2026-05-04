# Flujo de Sincronización opencode-synced

Guía completa para replicar configuración de OpenCode entre máquinas local y VPS usando el plugin `opencode-synced`.

## 1. Visión general

`opencode-synced` es un plugin de OpenCode que sincroniza configuración via Git.
Propósito: mantener misma configuración en máquina local y VPS sin copiar archivos manualmente.

Arquitectura:

```text
Máquina local: /sync-init ──→ repositorio Git local
                                    │ push/pull
VPS:          /sync-link <repo> ──→ clona/pulls configuración
```

**No reemplaza volúmenes Docker.** Se complementan. Ver [Volumen local vs Sync Git](#7-volumen-local-vs-sync-git).

## 2. Prerrequisitos

- **GitHub CLI autenticado**: `gh auth login` (o `GH_TOKEN` configurado)
- **Token personal**: `GH_TOKEN` con permisos `repo` para repositorios privados
- **Repositorio privado**: Creado en GitHub (o cualquier remote Git accesible)

> [!CAUTION]
> `GH_TOKEN` en variables de entorno expone el token a procesos y logs. Prefiere `gh auth login`.

## 3. Flujo local: `/sync-init`

Ejecuta en máquina local para inicializar repositorio Git y configurar `opencode-synced`.

```bash
# Abrir OpenCode
$ opencode

# En Command Palette (Ctrl+Shift+P), ejecutar
$ /sync-init

# Ingresar URL del remote cuando se solicite
# Ej: https://github.com/tu-usuario/tu-repo-sync.git
```

`/sync-init` crea:

1. Repositorio Git en directorio de configuración de OpenCode.
2. Commit inicial con estado actual de la config.
3. Remote configurado con URL proporcionada.
4. Push inicial a remote.

Resultado: configuración local versionada y lista para replicar.

## 4. Flujo VPS: `/sync-link <repo>`

Ejecuta en VPS para clonar configuración desde remote.

```bash
# SSH al VPS
$ ssh usuario@tu-vps

# Abrir OpenCode (o asegurar que ~/.config/opencode existe)
$ opencode

# En Command Palette (Ctrl+Shift+P)
$ /sync-link https://github.com/tu-usuario/tu-repo-sync.git
```

> [!CAUTION]
> `/sync-link` sobrescribe la configuración local del VPS con la del remote.
> Si el VPS ya tiene configuración propia, haz backup antes:
>
> ```bash
> $ cp -r ~/.config/opencode ~/.config/opencode.backup
> ```

`/sync-link`:

1. Clona repositorio al directorio de configuración.
2. Configura remote para futuros pulls/pushes.
3. Si existe config local, intenta merge con remote.

Actualizaciones posteriores:

```bash
# En cualquier máquina: bajar cambios remotos
$ /sync-pull

# Subir cambios locales
$ /sync-push
```

## 5. Qué sincroniza / qué no

| Categoría | Sync por default | Notas |
|-----------|------------------|-------|
| Config (`opencode.json`/`opencode.jsonc`) | ✅ Sí | Archivo principal de configuración |
| Plugins | ✅ Sí | Lista de plugins instalados |
| Skills | ✅ Sí | Skills personalizados de AI |
| Agents | ✅ Sí | Configuración de agentes |
| Themes | ✅ Sí | Temas y personalización visual |
| Model favorites | ✅ Sí | Modelos favoritos y presets |
| Secrets (API keys, tokens) | ❌ No | `includeSecrets: false`. Riesgo de exposición en Git |
| MCP secrets | ❌ No | Credenciales MCP siempre excluidas |
| Sessions | ❌ No | `includeSessions: false`. Contienen tokens activos |
| Prompt stash | ❌ No | `includePromptStash: false`. Datos locales |
| Multi-auth stores | ❌ No | Contienen tokens OAuth. `extraSecretPaths` es opt-in |
| OpenChamber config | ❌ No | Config del contenedor OpenChamber |

## 6. Seguridad

### Secrets excluidos por default

`includeSecrets: false` protege API keys, tokens de acceso y credenciales.
Sincronizar secrets en Git es riesgo de exposición — incluso en repos privados.

### Sesiones excluidas por default

`includeSessions: false` evita conflictos y exposición de sesiones activas.
Para sesiones multi-máquina, usa Turso (ver [sección 8](#8-sesiones-multi-máquina-con-turso)).

### Prompt stash excluido por default

`includePromptStash: false`. Contiene datos locales sin riesgo de conflicto cross-machine.

> [!WARNING]
> Almacenes multi-auth (ej. GitHub, GitLab OAuth tokens) no se sincronizan por default.
> `extraSecretPaths` permite incluir rutas específicas, pero es **opt-in avanzado**.
> Solo actívalo si entiendes el riesgo de exponer tokens OAuth en Git.

### Recomendación: repo privado

Usa **repositorio privado** para sync. Incluso así, evita sincronizar secrets.
Un repo público expondría toda tu configuración de OpenCode.

## 7. Volumen local vs Sync Git

| Aspecto | Volumen Docker | Git Sync |
|---------|----------------|----------|
| Propósito | Persistencia local ante recreación de contenedor | Replicación de configuración entre máquinas |
| Alcance | Una sola máquina | Múltiples máquinas |
| Qué preserva | Estado completo del contenedor (logs, DB, etc.) | Solo configuración de OpenCode |
| Frecuencia | Automático, continuo | Manual (`/sync-push`/`/sync-pull`) |
| Resuelve | "Perdí datos al recrear el contenedor" | "Quiero misma config en local y VPS" |

> [!NOTE]
> No son excluyentes. Usa ambos: volúmenes para persistencia local, Git sync para replicación multi-máquina.

## 8. Sesiones multi-máquina con Turso

Git sync **no** es ideal para sesiones. Cambian frecuentemente y generan conflictos en Git.

Para sesiones compartidas entre máquinas:

```bash
# Configurar Turso como backend de sesiones
$ /sync-sessions-backend turso

# Seguir asistente de configuración
$ /sync-sessions-setup-turso
```

Turso sincroniza sesiones en tiempo real sin pasar por Git.
Recomendado sobre Git sync para cualquier escenario multi-máquina con sesiones activas.

> [!WARNING]
> Si sincronizas sesiones via Git, esperas conflictos frecuentes.
> Dos máquinas modificando mismo archivo de sesiones → conflictos de merge cada vez.

## 9. Solución de problemas

### `/sync-link` sobrescribe configuración existente

```bash
# Backup antes de sync-link
$ cp -r ~/.config/opencode ~/.config/opencode.backup

# Después de sync, restaurar archivos específicos
$ cp ~/.config/opencode.backup/mi-config.json ~/.config/opencode/
```

### Conflictos Git

```bash
# Ver estado
$ git -C ~/.config/opencode status

# Resolver conflicto manualmente
$ git -C ~/.config/opencode mergetool

# O aceptar versión remota o local
$ git -C ~/.config/opencode checkout --theirs -- ruta/archivo
$ git -C ~/.config/opencode checkout --ours -- ruta/archivo
```

Si conflictos son recurrentes, revisa qué archivos sincronizar y excluye los que cambian frecuentemente por máquina.

### `GH_TOKEN` no configurado

```bash
# Verificar
$ echo $GH_TOKEN

# Configurar (token desde GitHub: Settings > Developer settings > Tokens)
$ export GH_TOKEN="ghp_tu_token_aqui"

# O mejor: autenticar CLI
$ gh auth login
```

> [!CAUTION]
> `GH_TOKEN` se expone en `ps` y logs de shell. Prefiere `gh auth login`.

### Auth GitHub expirada

```bash
# Verificar estado
$ gh auth status

# Re-autenticar
$ gh auth login
```

### JSONC comments perdidos en modificación

Si al modificar configuración sincronizada se pierden comentarios:

1. Verifica que tu editor soporte JSONC (no JSON plano).
2. Usa OpenCode para editar archivos `.jsonc`.
3. Si usas herramientas externas, asegura que preserven comentarios.
4. Como fallback, mantén backup de comentarios en otro archivo.

## Referencias

- [Spec sync-config](../openspec/specs/sync-config/spec.md) — Requisitos técnicos del seed/merge
- [Spec vps-quickstart](../openspec/specs/vps-quickstart/spec.md) — Quickstart de despliegue en VPS
- [README raíz](../README.md) — Inicio rápido del proyecto
