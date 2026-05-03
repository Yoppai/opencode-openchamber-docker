# Delta for runtime-validation

## ADDED Requirements

### Requirement: Exposición del binario tras instalación global

El sistema MUST exponer el binario `openchamber` en el PATH después de ejecutar `npm install -g @openchamber/web`.

#### Scenario: Instalación global exitosa

- GIVEN un entorno limpio con Node.js 22 y npm
- WHEN `npm install -g @openchamber/web@latest` finaliza con éxito
- THEN el comando `openchamber` es ejecutable desde cualquier directorio
- AND `openchamber --version` retorna una cadena de versión no vacía

### Requirement: Arranque del servidor con flags CLI

El sistema MUST iniciar el servidor OpenChamber al invocar `serve --foreground --host --port`.

#### Scenario: Servidor en foreground escucha en host y puerto definidos

- GIVEN `openchamber` instalado y disponible en PATH
- WHEN se ejecuta `openchamber serve --foreground --host 0.0.0.0 --port 3000`
- THEN el proceso inicia sin salir inmediatamente
- AND el servidor escucha en el puerto TCP 3000 ligado a 0.0.0.0

#### Scenario: Comando por defecto

- GIVEN que no se proporciona subcomando
- WHEN se ejecuta `openchamber --foreground --host 127.0.0.1 --port 3000`
- THEN el servidor arranca como si se hubiera especificado `serve`

### Requirement: Autenticación con password de UI

El sistema MUST aceptar la configuración del password de UI mediante `--ui-password` o la variable de entorno `OPENCHAMBER_UI_PASSWORD`.

#### Scenario: Password mediante flag CLI

- GIVEN una instancia de OpenChamber en ejecución
- WHEN se inicia con `--ui-password secret123`
- THEN la UI web requiere el password `secret123` para acceder

#### Scenario: Password mediante variable de entorno

- GIVEN la variable de entorno `OPENCHAMBER_UI_PASSWORD` configurada con `envpass`
- WHEN se inicia OpenChamber sin el flag `--ui-password`
- THEN la UI web requiere el password `envpass` para acceder

### Requirement: Riesgo de dependencias nativas en ARM64

El sistema MUST documentar la disponibilidad de prebuilds nativas para `better-sqlite3`, `node-pty` y `bun-pty` en `linux/amd64` y `linux/arm64`.

#### Scenario: Verificación de prebuilds en AMD64

- GIVEN un entorno de instalación AMD64
- WHEN se instala `@openchamber/web`
- THEN `better-sqlite3` y `node-pty` se instalan sin requerir toolchain de compilación

#### Scenario: Captura de riesgo en ARM64

- GIVEN un entorno ARM64 sin `build-essential`
- WHEN se instala `@openchamber/web`
- THEN cualquier fallo de compilación de módulo nativo es registrado
- AND se documenta el requisito fallback de `build-essential` y `python3`

### Requirement: Documento de decisión Go/No-go

El sistema MUST producir un documento de decisiones que declare Go o No-go para ch-02, incluyendo flags confirmados, variables de entorno requeridas, mitigaciones ARM y bloqueadores.

#### Scenario: Decisión Go con mitigaciones

- GIVEN todos los escenarios de validación producen resultados esperados
- WHEN concluye el spike
- THEN el documento declara `Go` para ch-02
- AND lista flags CLI confirmados, mapeos de variables de entorno y requisitos de build-tools para ARM

#### Scenario: No-go con bloqueadores

- GIVEN al menos una validación crítica falla (p. ej., binario ausente, crash del servidor, dependencia nativa sin resolver)
- WHEN concluye el spike
- THEN el documento declara `No-go` para ch-02
- AND enumera bloqueadores y pasos de remediación recomendados
