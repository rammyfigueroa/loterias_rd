# Validación de la Fase 8.5B-8B-10

Fecha: 2026-11-09.

## Resultado

La aplicación Cloudflare Access fue creada y asociada exclusivamente a
`sorteosdominicanos-api-staging`.

- Application ID: `dec22f7c-f1bd-46c9-a5a0-15b05b98cbad`.
- Tipo: `Self-hosted`.
- Alcance: `All traffic`.
- Aplicaciones Access existentes tras la operación: 1.
- Destinos de la aplicación: 1 Worker de staging.

## Política y autenticación

- Política: `sorteosdominicanos staging admin`.
- Policy ID: `b8fc62ea-3d4a-49d7-ba07-09fc1204f0f8`.
- Acción: `Allow`.
- Reglas: 1.
- Uso: 1 aplicación.
- Identidad: una cuenta administrativa exacta, omitida de la documentación.
- Denegación predeterminada: confirmada por el modelo de políticas de la
  aplicación.
- `Everyone`: ausente.
- `Bypass`: ausente.
- Dominio de correo amplio: ausente.
- Acceso anónimo: ausente.

El panel del Worker muestra `Worker Access`, alcance `All traffic` y la política
adjunta. El panel de aplicaciones muestra una sola aplicación `Self-hosted`, y
el panel de políticas muestra una sola política utilizada por una aplicación.

## Exposición

La aplicación Access no habilitó una entrada HTTP:

- `No URLs enabled`;
- `workers.dev Disabled`;
- Preview URLs sin target público;
- Custom Domains: ninguno;
- Routes: ninguna;
- cron: ninguno;
- URL pública nueva: ninguna.

La comprobación de la dirección `workers.dev` desactivada devolvió `HTTP 404`
con `error code: 1042` de Cloudflare. No ejecutó el endpoint `/health` del
Worker.

No se realizó una prueba de autenticación extremo a extremo porque no existe una
entrada HTTP habilitada. Esa prueba pertenece a la fase que autorice la entrada.

## D1

El comando de solo lectura:

```sh
npm run fixtures:staging:remote:dry-run
```

confirmó:

- cuenta `f171b568e3a3a203a09ef2fd6e337a2c`;
- D1 `sorteosdominicanos-db-staging`;
- UUID `f31aac48-f437-4fd7-9691-a7e976010dc6`;
- binding `HISTORY_DB`;
- 16 resultados sintéticos;
- 19 registros de cobertura;
- 1 revisión;
- estado `ALREADY_APPLIED`;
- `writesExecuted: false`;
- `applyEnabled: false`.

## Aislamiento

No se desplegó código. No se modificaron Worker `api`,
`sorteosdominicanos-app`, D1, DNS, rutas, dominios, previews, secretos,
facturación, Flutter ni configuración nativa.

## Git

Durante esta fase solo se añadieron los documentos 90 y 91. El repositorio ya
contenía cambios previos y archivos sin seguimiento; se conservaron sin
alterarlos. No se creó commit, push ni Pull Request.

## Riesgo pendiente

Access está correctamente asociado, pero todavía no puede probarse la respuesta
de login o denegación desde Internet porque el Worker no tiene URL. La siguiente
fase debe habilitar una sola entrada autorizada y ejecutar pruebas positivas y
negativas antes de considerar staging accesible.

**ACCESS CONFIGURADO - WORKER AUN SIN EXPOSICION HTTP**
