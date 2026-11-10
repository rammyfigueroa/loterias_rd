# Cierre de la Fase 8.9

Fecha: 2026-11-09.

## Alcance conservado

Este cierre conserva el desarrollo experimental autorizado de las fases
8.0-8.8. Relaciones Históricas permanece oculta y utiliza datos sintéticos
solo en el repositorio local de pruebas. La API pública no ofrece todavía un
historial verificable suficiente para activar la función.

## Manifiesto incluido

### Documentación

- `docs/popular_numbers/01_inventario_fuentes.md` hasta
  `docs/popular_numbers/103_validacion_fase8_7.md`, numerados de forma continua.
- `docs/popular_numbers/110_integracion_practica.md`.
- `docs/popular_numbers/111_cierre_fase8_9.md`.

### Backend y staging

- `loterias_rd_api/package.json`.
- `loterias_rd_api/wrangler.staging.toml`.
- `loterias_rd_api/src/statistics/routes.js`.
- `loterias_rd_api/src/statistics/number-transitions.js`.
- `loterias_rd_api/src/statistics/number-transitions-service.js`.
- `loterias_rd_api/fixtures/staging/base-fixture-v1.sql`.
- `loterias_rd_api/scripts/generate-staging-fixture-sql.js`.
- `loterias_rd_api/scripts/load-staging-fixtures-local.js`.
- `loterias_rd_api/scripts/load-staging-fixtures-remote.js`.
- `loterias_rd_api/scripts/staging-fixtures.js`.
- `loterias_rd_api/test/number-transitions.test.js`.
- `loterias_rd_api/test/number-transitions-integration.test.js`.
- `loterias_rd_api/test/staging-fixture-sql.test.js`.
- `loterias_rd_api/test/staging-fixtures.test.js`.
- `loterias_rd_api/test/staging-fixtures-remote.test.js`.

### Flutter

- `loterias_rd_app/lib/app/app_features.dart`.
- `loterias_rd_app/lib/features/results/presentation/stats_page.dart`.
- `loterias_rd_app/lib/features/historical_relations/application/historical_relations_controller.dart`.
- `loterias_rd_app/lib/features/historical_relations/data/historical_relations_repository.dart`.
- `loterias_rd_app/lib/features/historical_relations/domain/historical_relations.dart`.
- `loterias_rd_app/lib/features/historical_relations/presentation/historical_relations_navigation.dart`.
- `loterias_rd_app/lib/features/historical_relations/presentation/historical_relations_page.dart`.
- `loterias_rd_app/test/historical_relations_test.dart`.

Total previsto: 128 archivos.

## Exclusiones

- `.idea/` y `.DS_Store`.
- `loterias_rd_app/ios/`.
- `docs/dreams_numbers/77_auditoria_sincronizacion.md`.
- Builds, temporales, credenciales y cualquier cambio ajeno.

## Seguridad y configuración

- `AppFeatures.historicalRelationsEnabled = false`.
- `AppFeatures.dreamsNumbersEnabled = false`.
- Staging usa un Worker y una D1 independientes.
- No se incluyen tokens, contraseñas, cookies, service tokens, claves privadas,
  datos personales, información bancaria, certificados ni keystores.
- Los fixtures son sintéticos y no forman parte de los assets de producción.
- El endpoint experimental no fue incorporado al Worker público de producción.

## Validaciones

- Flutter: 151/151 pruebas aprobadas.
- Backend: 109/109 pruebas aprobadas.
- Flutter analyze: 53 avisos preexistentes, sin errores nuevos de esta fase.
- Validación Node: todos los archivos JavaScript nuevos y modificados pasan
  `node --check`.
- `git diff --cached --check` y `git diff --check`: sin errores de whitespace.
- Índice validado contra el manifiesto: 128 archivos.

## Commit

Mensaje autorizado:

`feat: preserve historical relations behind disabled feature flag`

El hash se registra en el informe posterior porque un commit no puede contener
su propio identificador definitivo.

## Condiciones para retomar

La funcionalidad solo debe conectarse y activarse cuando exista un historial
público continuo y verificable por serie, con identificadores estructurados,
cobertura, revisiones y suficientes eventos para calcular transiciones sin
mezclar sorteos ni interpretar huecos como continuidad.
