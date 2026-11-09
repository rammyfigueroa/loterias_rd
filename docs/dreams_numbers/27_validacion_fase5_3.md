# Validación de la Fase 5.3

## Alcance ejecutado

Se auditó el modelo, cargador, esquema, validadores, gate, wrapper, pruebas y la
documentación 01-24. Se incorporó evidencia de derechos y soporte mínimo para
artículos culturales independientes. No se modificaron Worker, D1, endpoints,
dependencias, configuración nativa ni otras funciones de la aplicación.

## Casos cubiertos

Las pruebas sintéticas comprueban evidencia válida, alcance, vigencia,
territorio, uso comercial, redistribución, integridad referencial, inmutabilidad,
búsqueda y descifrador. Los casos negativos cubren evidencia o fuente
inexistente, titular vacío, alcance insuficiente, prohibiciones comerciales o de
redistribución, permisos vencidos o futuros, territorio y restricciones
incompatibles, revisión pendiente, licencia abierta no verificada, uso cruzado
de autorización de artículo y fuentes `authorized` sin evidencia.

El piloto cultural se mantiene en documentación, con cinco borradores `review`.
No se incorporaron las 15 fichas piloto, tablas comerciales ni asociaciones
numéricas reales.

## Resultado

- `flutter test`: **115 pruebas aprobadas, 0 fallidas**.
- `flutter analyze` aislado del módulo y sus pruebas: **sin problemas**.
- `flutter analyze` global: **53 avisos preexistentes fuera del módulo**, sin
  errores ni incidencias nuevas en Sueños y Números.
- `git diff --check`: correcto.
- JSON del esquema y fixture sintético: sintaxis válida con `jq empty`.
- Build o despliegue: no ejecutado por restricción.

## Riesgos pendientes

- No existe evidencia jurídica real aprobada para S06-S10.
- El esquema se valida estructuralmente en Dart; no hay motor JSON Schema en
  runtime.
- Las restricciones contractuales deben codificarse de forma consistente en el
  contexto de publicación.
- Los artículos requieren localización bibliográfica, revisión editorial y
  evaluación jurídica antes de pasar de `review`.
