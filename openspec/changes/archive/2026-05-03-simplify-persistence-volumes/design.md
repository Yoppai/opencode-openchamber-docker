# Design: simplify-persistence-volumes

## Technical Approach

Reducir matriz de volúmenes de 10 a 2 usando mount padre `./data/home → /home/openchamber`. Esto cubre automáticamente cualquier path que plugins futuros escriban bajo `$HOME`. Workspaces se mantiene separado para gestión independiente de código fuente.

### docker-compose.yml (MODIFIED)

Reemplazar bloque `volumes:` completo. De 10 mounts a 2:

```yaml
volumes:
  # Persiste todo /home/openchamber: config, cache, state, agents, gh, ssh, plugins
  - ./data/home:/home/openchamber
  # Workspaces separado: código fuente, gestión independiente
  - ./workspaces:/home/openchamber/workspaces
```

### scripts/init-dirs.sh (MODIFIED)

Simplificar de 10 `mkdir -p` a 2. Eliminar bloque SSH (vive dentro de home). Agregar `chmod 755` defensivo.

```bash
mkdir -p data/home
mkdir -p workspaces
chmod 755 data/home workspaces
```

### entrypoint.sh (MODIFIED)

Cambiar bloque SSH: de silencioso (`2>/dev/null || true`) a no silencioso con warning:

```bash
if [ -d "$HOME/.ssh" ]; then
  chmod 700 "$HOME/.ssh" || echo "[entrypoint] WARNING: no se pudo aplicar chmod 700 a ~/.ssh" >&2
fi
```

## Architecture Decisions

### AD-1: Mount padre `data/home → ~` en vez de mounts individuales
**Decisión**: Usar un solo mount para todo `/home/openchamber`.
**Rationale**: Plugins arbitrarios pueden escribir en paths no previstos (`~/.agent-browser`, `~/.npm`, `~/.bun`). Mount padre = zero-config persistence.
**Alternativas**: Mantener 10 mounts específicos requeriría adivinar paths de plugins futuros.
**Tradeoff**: Cache y config comparten mount. Aceptable: `data/home/.cache` se puede borrar sin afectar config.

### AD-2: Workspaces separado
**Decisión**: Mantener `./workspaces → ~/workspaces` como mount independiente.
**Rationale**: Código fuente (GBs) vs config (MBs). Separación permite borrar config sin perder código.
**Alternativas**: Workspaces dentro de `data/home/workspaces` → 1 solo mount. Rechazado: mezcla propósitos.

### AD-3: SSH sin mount aislado
**Decisión**: SSH vive dentro de `data/home/.ssh/`, no como mount separado.
**Rationale**: SSH no es flujo oficial (solo `gh auth login` / `GH_TOKEN`). Entrypoint maneja permisos defensivamente.
**Alternativas**: Mount separado `data/ssh → ~/.ssh`. Rechazado: complejidad innecesaria para flujo no soportado.

### AD-4: chmod SSH no silencioso
**Decisión**: `entrypoint.sh` reporta warning si `chmod 700 ~/.ssh` falla.
**Rationale**: Error silencioso causa fallos crípticos en SSH. Warning visible = usuario sabe qué corregir.
**Alternativas**: `2>/dev/null || true`. Rechazado: oculta el problema.

## File Changes

| File | Action | Purpose |
|---|---|---|
| `docker-compose.yml` | MODIFY | Reemplazar 10 volumes por 2 |
| `scripts/init-dirs.sh` | MODIFY | Simplificar a 2 directorios |
| `entrypoint.sh` | MODIFY | chmod SSH no silencioso |
| `openspec/specs/persistence/spec.md` | MODIFY | Matriz simplificada 10→2 |

## Risks

| Risk | Mitigation |
|---|---|
| Home completo persiste más datos | Beneficio, no riesgo |
| Host UID ≠ 1000 | chmod 755 en init-dirs.sh + nota chown |
| SSH permisos heredados | entrypoint.sh chmod 700 con warning |
