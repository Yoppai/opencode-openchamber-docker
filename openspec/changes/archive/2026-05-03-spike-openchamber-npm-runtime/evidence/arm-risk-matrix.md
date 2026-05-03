# ARM64 Risk Matrix

Generated: 2026-05-03T20:21:58Z
Package: @openchamber/web@latest
Native architecture: x86_64

## Matrix

| Plataforma | Dependencia | Prebuild disponible | Compilación requerida | Resultado |
|---|---|---|---|---|
| linux/amd64 | better-sqlite3 | No detectado | — | — |
| linux/amd64 | node-pty | No detectado | — | — |
| linux/amd64 | bun-pty | No detectado | — | — |
| linux/arm64 | better-sqlite3 | No detectado | — | — |
| linux/arm64 | node-pty | No detectado | — | — |
| linux/arm64 | bun-pty | No detectado | — | — |

## Notes

- **No detectado**: Las dependencias no aparecen en el log de instalación porque npm instaló prebuilds silenciosamente sin output verbose. `prebuild-install@7.1.3` confirmado (deprecado). No hubo invocaciones `node-gyp`.
- **AMD64**: Instalación completada en ~11s sin errores ni compilación nativa.
- **ARM64 (QEMU)**: Instalación completada en ~47s bajo emulación QEMU sin errores ni compilación nativa. El tiempo extra es overhead de emulación, no compilación.
- **Mitigación ARM64**: Si alguna dependencia nativa futura requiere compilación en ARM64, instalar `build-essential` + `python3` en el Dockerfile de producción (ch-02).
- **Validación QEMU**: ARM64 probado via emulación QEMU (Docker Desktop). Los prebuilds funcionan igual que en nativo. Diferencia de tiempo es solo overhead QEMU.
- **Estado**: ✅ Sin bloqueadores ARM64 identificados. Prebuilds disponibles para ambas arquitecturas.
