# container-image Specification

## Purpose
Define comportamiento observable de la imagen Docker de producción que empaqueta OpenCode, OpenChamber y herramientas requeridas.

## Requirements

### Requirement: Build arguments para versiones
La imagen MUST aceptar build args `OPENCODE_VERSION` y `OPENCHAMBER_VERSION`.

#### Scenario: Build con versiones explicitas

- GIVEN un build de imagen
- WHEN se pasan `--build-arg OPENCODE_VERSION=1.0.0 --build-arg OPENCHAMBER_VERSION=1.9.10`
- THEN la imagen resultante contiene esas versiones instaladas

### Requirement: Binarios disponibles en PATH
La imagen MUST exponer `opencode`, `openchamber`, `bun`, `gh`, `git`, `ssh` y `tini` ejecutables desde PATH.

#### Scenario: Verificación de binarios tras build

- GIVEN una imagen construida exitosamente
- WHEN se ejecuta cada binario con flag `--version` (o `-V`/`ssh -V`)
- THEN retorna versión sin error distinto de cero

### Requirement: Resolución del bloqueador de OpenChamber
La imagen MUST permitir que `openchamber serve` localice el CLI de OpenCode.

#### Scenario: Serve arranca sin error de CLI ausente

- GIVEN un contenedor iniciado desde la imagen
- WHEN se ejecuta `openchamber serve --foreground --host 0.0.0.0 --port 3000`
- THEN el proceso permanece activo mayor a 5 segundos
- AND no aparece mensaje "Unable to locate the opencode CLI"

### Requirement: Compatibilidad Debian/glibc
La imagen MUST usar base Debian/glibc compatible. Alpine/musl MUST NOT usarse.

#### Scenario: Base runtime verificada

- GIVEN una imagen construida
- WHEN se inspecciona el sistema base
- THEN reporta glibc como C library
- AND no reporta musl
