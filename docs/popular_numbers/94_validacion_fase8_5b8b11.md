# Validación de la Fase 8.5B-8B-11

Fecha: 2026-11-09.

## Resultado

Se habilitó una única entrada HTTP protegida:

```text
https://sorteosdominicanos-api-staging.sorteosdominicanos.workers.dev
```

Cloudflare confirmó que la aplicación Access existente protege esa URL. Las
Preview URLs permanecen desactivadas y no existen Custom Domains ni Routes.

## Access

- Application ID: `dec22f7c-f1bd-46c9-a5a0-15b05b98cbad`.
- Policy ID: `b8fc62ea-3d4a-49d7-ba07-09fc1204f0f8`.
- Alcance: `All traffic`.
- Acción: `Allow` para una identidad administrativa exacta.
- Solicitudes anónimas: bloqueadas por redirección al login de Access.
- Solicitud administrativa: permitida mediante el flujo oficial.
- `Everyone`: ausente.
- `Bypass`: ausente.
- Políticas adicionales: ninguna.

## Endpoint

`GET /statistics/number-transitions` devolvió para el número `24`:

- `67`: 3 transiciones, frecuencia `0.6`;
- `24`: 1 transición, frecuencia `0.2`;
- `32`: 1 transición, frecuencia `0.2`;
- total: 5.

Los resultados proceden únicamente del fixture sintético y no representan una
predicción.

## Aislamiento

- Worker staging: sin despliegues nuevos; deployment
  `62246203-a1a9-4f3e-9808-0e6baea1f8cf` y versión
  `1cc2db30-e9d0-48e6-886d-28de07b918e5` sin cambios.
- Worker `api`: no se desplegó ni modificó.
- `sorteosdominicanos-app`: no se desplegó ni modificó.
- D1 staging: `16/19/1`, sin escrituras.
- D1 de producción: no utilizada.
- DNS: sin cambios.
- Facturación: sin cambios.
- Preview URLs: desactivadas.
- Custom Domains y Routes: ninguno.
- Cron y secrets: no creados.

## Git

Durante esta fase se añadieron únicamente los documentos 92, 93 y 94. Los
cambios y archivos sin seguimiento preexistentes se conservaron. No se creó
commit, push ni Pull Request.

## Riesgo residual

La URL de staging permanece disponible en Internet, pero toda solicitud está
sujeta a Cloudflare Access. Cambios futuros a la aplicación, política o alcance
de Access deben repetir primero la prueba anónima. No debe habilitarse ninguna
preview ni segunda entrada sin una autorización separada.

**ENTRADA STAGING HABILITADA Y PROTEGIDA POR ACCESS**
