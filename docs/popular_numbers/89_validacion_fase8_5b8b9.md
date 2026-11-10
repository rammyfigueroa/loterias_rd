# Validación de la Fase 8.5B-8B-9

Fecha: 2026-11-09.

## Resultado

El Worker staging fue creado correctamente sin targets públicos.

- Cuenta: `f171b568e3a3a203a09ef2fd6e337a2c`.
- Worker: `sorteosdominicanos-api-staging`.
- Deployment ID: `62246203-a1a9-4f3e-9808-0e6baea1f8cf`.
- Version ID: `1cc2db30-e9d0-48e6-886d-28de07b918e5`.
- Número de versión: `1`.
- Configuración: `loterias_rd_api/wrangler.staging.toml`.
- Targets desplegados: ninguno.

## Configuración de seguridad

- `workers_dev`: desactivado.
- Preview URLs: desactivadas en Wrangler.
- Rutas: ninguna.
- Custom Domains: ninguno.
- Cron: ninguno.
- Secrets: ninguno creado.
- Aplicaciones Access: ninguna creada.
- Políticas Access: ninguna creada.

El metadato `has_preview: true` pertenece a la versión remota, pero no se
publicó un target de preview. La configuración explícita mantiene
`preview_urls = false` y la comprobación de la URL `workers.dev` devolvió la
respuesta de Cloudflare `404 / error 1042`, no la ejecución del Worker.

## Binding D1

- Binding: `HISTORY_DB`.
- Base: `sorteosdominicanos-db-staging`.
- UUID: `f31aac48-f437-4fd7-9691-a7e976010dc6`.
- Resultados sintéticos: 16.
- Coberturas: 19.
- Revisiones: 1.
- Estado del fixture: `ALREADY_APPLIED`.
- Escrituras durante esta fase: ninguna.

## Dry-run

- Resultado: aprobado.
- Carga: `81.36 KiB`.
- Gzip: `18.96 KiB`.
- Binding inesperado: ninguno.
- Variable secreta: ninguna.

## Aislamiento

Los listados de deployments posteriores conservaron los mismos identificadores
observados antes del cambio para:

- Worker de producción `api`;
- aplicación `sorteosdominicanos-app`.

No se desplegó código hacia esos recursos. No se modificaron D1, DNS, Access,
rutas, dominios, cron ni secretos.

## Git

No se modificó código ni configuración durante esta fase. Solamente se añadieron
los documentos 88 y 89. No se creó commit, push ni Pull Request. El repositorio
conserva cambios previos no relacionados que no fueron alterados.

## Próxima autorización requerida

Antes de habilitar cualquier entrada, una fase separada debe:

1. confirmar la identidad administrativa exacta;
2. obtener el identificador requerido por la aplicación Access;
3. crear la política `Allow` restringida;
4. asociar Access al Worker completo;
5. probar denegación anónima;
6. habilitar solo una entrada autorizada.

**WORKER STAGING CREADO — SIN EXPOSICIÓN HTTP PÚBLICA**
