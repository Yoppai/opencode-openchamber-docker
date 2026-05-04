# Guía de Troubleshooting

Problemas comunes, causas raíz y mitigaciones para `opencode-openchamber-docker`.

---

## Índice

- [1. Autenticación GitHub](#1-autenticación-github)
- [2. Claves SSH](#2-claves-ssh)
- [3. Dependencias ARM64](#3-dependencias-arm64)
- [4. UI_PASSWORD vacío](#4-ui_password-vacío)
- [5. General](#5-general)

---

## 1. Autenticación GitHub

### Síntoma

Error `401 Unauthorized` o `403 Forbidden` al hacer pull/push de imágenes GHCR,
o `git push` rechazado al sincronizar configuración.

### Causa

- `GITHUB_TOKEN` expirado o con scopes insuficientes
- Falta scope `packages:write` para GHCR
- SSH key no registrada en GitHub
- Token personal (`GH_TOKEN`) sin permiso `repo`

### Mitigación

**Para GHCR:**
```bash
# Verificar autenticación actual
$ gh auth status

# Re-autenticar con scopes correctos
$ gh auth login --scopes "read:packages,write:packages,repo"

# O usar token personal
$ export GH_TOKEN="ghp_tu_token_aqui"  # Requiere scope: repo y packages:write
```

### Prevención

- Usa `gh auth login` en lugar de `GH_TOKEN` en variables de entorno
- Configura un token clásico con expiración larga para servidores headless
- Habilita GitHub CLI en el VPS: `gh auth login --hostname github.com`

---

## 2. Claves SSH

### Síntoma

```
Permission denied (publickey)
```
Al intentar `git clone`, `git push`, o sincronizar con repositorio privado via SSH.

### Causa

- Clave privada no cargada en `ssh-agent`
- Clave pública no registrada en GitHub → Settings → SSH and GPG keys
- Formato de clave incorrecto o permisos incorrectos en `~/.ssh/`

### Mitigación

```bash
# 1. Verificar claves existentes
$ ls -la ~/.ssh/

# 2. Cargar clave en ssh-agent
$ eval "$(ssh-agent -s)"
$ ssh-add ~/.ssh/id_ed25519   # o ~/.ssh/id_rsa

# 3. Probar conexión
$ ssh -T git@github.com
# → "Hi username! You've successfully authenticated..."

# 4. Si no funciona, registrar clave pública en GitHub:
#    Settings → SSH and GPG keys → New SSH key
#    Pegar contenido de ~/.ssh/id_ed25519.pub
```

### Prevención

- Genera una clave dedicada para el VPS: `ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""`
- Agrega la clave pública a GitHub
- Configura `~/.ssh/config` para usar la clave correcta automáticamente:

```
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
```

## 3. Dependencias ARM64

### Síntoma

```
exec format error
```
O el contenedor falla al arrancar con errores de librerías nativas no encontradas.
Común en Raspberry Pi, Apple Silicon (Docker en Mac M1/M2/M3), o VPS ARM64.

### Causa

Alguna dependencia upstream no tiene binario precompilado para `linux/arm64`.
Esto puede ocurrir con paquetes npm que incluyen binarios nativos
(ej. `better-sqlite3`, `node-pty`).

### Mitigación

1. **Verificar multi-arch:** la imagen oficial se publica con manifiesto
   multi-arch (`linux/amd64`, `linux/arm64`). Confirma que tu tag incluye ARM64:

   ```bash
   $ docker buildx imagetools inspect ghcr.io/yoppai/opencode-openchamber:latest
   ```

2. **Forzar arquitectura explícita** (solución temporal):

   ```bash
   $ docker compose up -d --platform linux/arm64 openchamber
   ```

3. **Build local** si la imagen precompilada no funciona:

   ```bash
   $ docker compose build --platform linux/arm64 openchamber
   ```

### Si el problema persiste

- Reporta un issue en el repositorio con:
  - Salida de `uname -m`
  - Logs completos del build/arranque
  - Tag de imagen usado
- Incluye si el error ocurre en pull (`manifest unknown`) o en runtime

---

## 4. UI_PASSWORD vacío

### Síntoma

Advertencia en los logs del contenedor:

```
UI_PASSWORD no configurado o vacío
```

### Causa

La variable `UI_PASSWORD` no está definida en el archivo `.env`,
o `.env.example` fue copiado pero no se editó.

### Mitigación

```bash
# 1. Verificar estado actual
$ grep UI_PASSWORD .env

# 2. Si está vacío o no existe:
$ cp .env.example .env   # si no existe .env

# 3. Editar .env y definir una contraseña segura
#    UI_PASSWORD=tu_contraseña_segura_aqui

# 4. Reiniciar el contenedor
$ docker compose up -d openchamber
```

### Prevención

- Siempre define `UI_PASSWORD` en `.env` antes del primer `docker compose up`
- Usa una contraseña **fuerte** (mínimo 16 caracteres, alfanumérica + símbolos)
- Para entornos cloud, `UI_PASSWORD` es obligatorio — sin ella la UI queda
  expuesta sin autenticación

---

## 5. General

### El contenedor no arranca

```bash
# Ver logs
$ docker compose logs openchamber

# Verificar estado
$ docker compose ps

# Forzar recreación
$ docker compose up -d --force-recreate openchamber
```

### Puerto en uso

```bash
# Error: port is already allocated
# Cambiar puerto en .env:
#   OPENCHAMBER_PORT=3001
# Luego:
$ docker compose up -d openchamber
```

### Permisos de volúmenes

```bash
# Error: permission denied al escribir en ./data/
$ sudo chown -R 1000:1000 ./data
$ sudo chown -R 1000:1000 ./workspaces
```

### Directorios de volumen faltantes

```bash
# Error: no such file or directory
$ ./scripts/init-dirs.sh   # Crea directorios necesarios
$ docker compose up -d openchamber
```

---

## Referencias

- [README: Quickstart](../README.md#quickstart)
- [Política de actualización](update-policy.md)
