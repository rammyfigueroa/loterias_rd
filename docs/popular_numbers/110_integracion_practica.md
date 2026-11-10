# Integración práctica de Relaciones Históricas

Fecha: 2026-11-09.

## Revisión realizada

Se inspeccionaron el endpoint público `/results`, `LotteryResult`,
`LotteryResultsRemoteSource`, el catálogo de loterías, las series estadísticas y
el módulo local de Relaciones Históricas. No se consultó staging ni se modificó
infraestructura.

La respuesta pública observada contenía 90 resultados y siete fechas distintas.
Para las series objetivo solo había un resultado de Lotería Nacional y uno de
Gana Más. Una transición necesita al menos dos eventos cronológicos de la misma
serie.

## Qué puede reutilizarse

- cliente HTTP y configuración pública de `/results`;
- fecha, nombre visible, premios y primera posición;
- selectores, rangos, caché y controlador de Relaciones Históricas;
- IDs estructurados ya definidos para las series estadísticas;
- estados de carga, vacío, error y protección frente a respuestas tardías.

## Bloqueo real

1. `/results` contiene resultados recientes, no un historial continuo: solo hay
   un evento para cada serie objetivo.
2. La respuesta no incluye `operatorId` ni `drawId`; identificar series por
   nombres contradiría el aislamiento estructurado requerido.
3. No existe cobertura diaria para distinguir resultado ausente, fallo de
   consulta y día sin sorteo.
4. No existen revisión/fingerprint ni paginación histórica que permitan detectar
   correcciones, duplicados o snapshots incompletos.
5. `LotteryResult` tampoco conserva `sourceId` o `updatedAt`, aunque esos campos
   aparezcan en la respuesta pública.

Por estas razones no se sustituyó el repositorio local por un cálculo basado en
`/results`: produciría estados vacíos o estadísticas no verificables y podría
tratar huecos como continuidad.

## Estado funcional

- La interfaz, filtros y controlador continúan implementados.
- `LocalHistoricalRelationsRepository` permanece disponible solo para pruebas y
  revisión local.
- No se usaron fixtures de staging como datos reales.
- No se añadieron HTTP, credenciales, cookies, tokens o URLs administrativas.
- `AppFeatures.historicalRelationsEnabled = false`.
- `AppFeatures.dreamsNumbersEnabled = false`.

## Solución concreta

Ampliar únicamente la respuesta pública existente con una colección histórica
de solo lectura que incluya `operatorId`, `drawId`, fecha ISO, primera posición,
identidad estable, cobertura y revisión, o exponer esos mismos campos mediante
el endpoint público de transiciones ya diseñado. Cuando existan al menos dos
eventos verificables por serie, Flutter podrá sustituir el repositorio local por
el repositorio HTTP sin cambiar la pantalla ni el controlador.

No se requiere conectar la app a staging, copiar su D1 ni incorporar Access.

## Pruebas

- No se añadieron pruebas porque no se modificó código funcional.
- `flutter test`: 151/151 pruebas aprobadas.
- `npm test`: 109/109 pruebas backend aprobadas.
- `flutter analyze --no-fatal-infos --no-fatal-warnings`: salida correcta con
  los 53 avisos preexistentes y sin errores nuevos de esta fase.
- `git diff --check`: sin errores de whitespace.

**INTEGRACIÓN BLOQUEADA POR HISTORIAL PÚBLICO INSUFICIENTE**
