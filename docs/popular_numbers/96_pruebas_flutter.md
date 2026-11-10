# Pruebas Flutter de Relaciones Históricas

Fecha: 2026-11-09.

## Suite específica

Archivo: `loterias_rd_app/test/historical_relations_test.dart`.

La suite cubre:

1. bandera desactivada por defecto;
2. conservación de `dreamsNumbersEnabled = false`;
3. tarjeta oculta;
4. navegación bloqueada;
5. navegación habilitada solo mediante inyección de prueba;
6. selección independiente de serie;
7. selección y normalización de número;
8. rango incompleto e invertido;
9. rango válido y `Todo el historial`;
10. cobertura incompleta;
11. carga, datos, vacío y error;
12. orden determinista;
13. conteos y frecuencias;
14. descarte de respuestas tardías;
15. caché por todos los filtros;
16. presentación y lenguaje no predictivo;
17. layout a 320 dp;
18. ausencia de HTTP, URLs y material de credenciales.

Resultado específico final: **17 pruebas aprobadas**. Algunas comprobaciones
agrupan más de un criterio de la lista anterior.

## Suite global

Comando:

```text
flutter test
```

Resultado final: **151/151 pruebas aprobadas**.

La línea base anterior era 134 pruebas. Esta fase añadió 17 pruebas sin romper
las suites de Coincidencias de Primera, resultados, inicio ni Sueños y Números.

## Análisis estático

Comando:

```text
flutter analyze --no-fatal-infos --no-fatal-warnings
```

Resultado: 53 avisos globales preexistentes y ningún aviso nuevo en
`features/historical_relations` ni en `historical_relations_test.dart`.

Los avisos existentes corresponden principalmente a APIs deprecadas y elementos
sin uso en pantallas anteriores fuera del alcance de esta fase.

## Aislamiento

Una prueba inspecciona todos los fuentes del módulo y rechaza:

- `package:http`;
- URLs `https://`;
- `access_token`;
- `password`;
- referencias a Cloudflare.

Esto complementa la revisión manual y confirma que la interfaz usa únicamente
el repositorio sintético local.
