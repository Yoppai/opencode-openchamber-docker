# Spec: Spec Domain Registry

## Purpose

Define comportamiento observable de la formalización OpenSpec para el roadmap Docker. Este spec describe qué debe producirse cuando el change `formalize-docker-roadmap` se completa.

## Requirements

### Requirement: PRD Acceptance Criteria Mapping

El sistema MUST mapear cada criterio de aceptación PRD §504-513 a exactamente un artifact OpenSpec: spec, design o task.

#### Scenario: Mapeo completo de 10 criterios

- GIVEN PRD §504-513 con 10 criterios de aceptación
- WHEN se ejecuta clasificación
- THEN cada criterio aparece en tabla con artifact destino único (spec, design o task)
- AND ningún criterio queda sin clasificar

#### Scenario: Encabezado PRD fuera de conteo

- GIVEN PRD §502-503 como contexto de sección
- WHEN se revisa el bloque
- THEN se documenta como ancla de alcance
- AND no se cuenta como criterio de aceptación

#### Scenario: Criterio observable vs técnico

- GIVEN criterio §504 (CI publica imagen multi-arch)
- WHEN se clasifica
- THEN se etiqueta como `spec` en dominio `ghcr-publishing`
- AND criterio §508 (entrypoint inyecta `--ui-password`) se etiqueta como `design`

### Requirement: Candidate Spec Domains Declaration

El sistema MUST declarar seis dominios spec candidatos para changes posteriores, con nombre kebab-case, descripción corta, changes relacionados y estado registrado.

#### Scenario: Registro de dominios

- GIVEN changes ch-01..ch-07 en ROADMAP
- WHEN se crea registro de dominios
- THEN aparecen `container-image`, `runtime-config`, `persistence`, `sync-config`, `ghcr-publishing`, `vps-quickstart`
- AND cada dominio lista sus changes relacionados

#### Scenario: Dominio sin spec previa

- GIVEN directorio `openspec/specs/` vacío
- WHEN se declaran dominios candidatos
- THEN se crean directorios con `README.md` placeholder en `openspec/specs/<domain>/`
- AND ninguno contiene `spec.md` todavía

### Requirement: Later Changes Remain Deferred

El sistema MUST NOT convertir ch-01..ch-07 en comportamiento completado dentro de ch-00.

#### Scenario: Sólo registro, no implementación

- GIVEN se inspecciona `openspec/changes/formalize-docker-roadmap/`
- WHEN se listan artifacts
- THEN no existen `Dockerfile`, `entrypoint.sh`, `docker-compose.yml` ni workflows
- AND los cambios ch-01..ch-07 quedan sólo como destinos registrados

### Requirement: ROADMAP Traceability Update

El sistema MUST actualizar `openspec/ROADMAP.md` para reflejar que ch-00 está en progreso y vincular sus artifacts.

#### Scenario: Estado ch-00 visible

- GIVEN ROADMAP muestra ch-00 como Pending
- WHEN formalización avanza
- THEN fila ch-00 muestra estado `in-progress`
- AND enlaza a `openspec/changes/formalize-docker-roadmap/`

### Requirement: Scope Boundary Enforcement

El change ch-00 MUST NOT incluir archivos de implementación Docker, runtime, CI ni Compose.

#### Scenario: Sin artifacts de implementación

- GIVEN se inspecciona `openspec/changes/formalize-docker-roadmap/`
- WHEN se lista contenido
- THEN NO existe `Dockerfile`, `entrypoint.sh`, `docker-compose.yml`, `.github/workflows/`
- AND proposal out-of-scope documenta explícitamente exclusión

#### Scenario: Sin modificación de código producto

- GIVEN repositorio tiene código fuente de aplicación
- WHEN ch-00 se aplica
- THEN ningún archivo fuente de la aplicación se modifica
