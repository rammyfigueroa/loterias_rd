# Pruebas de fixtures sintéticos

Fecha: 2026-11-09.

## Archivo

Las pruebas están en
`loterias_rd_api/test/staging-fixtures.test.js`. Cada prueba D1 crea una
instancia local de Miniflare/Wrangler con `persist: false` y
`remoteBindings: false`, aplica las migraciones y se destruye al finalizar.

## Casos cubiertos

1. Generación base determinista y exclusivamente sintética.
2. Rechazo de modo remoto y exigencia de destino local explícito.
3. Rechazo de configuración, base o exposición no autorizadas.
4. Rechazo de una base local con tablas ajenas.
5. Primera carga e idempotencia en segunda carga.
6. Colisión con dato ajeno sin sobrescritura.
7. Transiciones conocidas y frecuencias exactas.
8. Repetición `24 -> 24` y empate entre destinos.
9. `NO_DRAW_SCHEDULED` con verificación.
10. Corrección canónica y trazabilidad en `result_revisions`.
11. Cobertura incompleta y desconocida.
12. Aislamiento entre Gana Más y Lotería Nacional.
13. Rango corto inclusivo y origen sin transiciones.
14. Caché `MISS`/`HIT` sobre el mismo fingerprint.
15. Generador determinista y carga de 5,000 eventos.
16. Análisis del fixture amplio: 50 transiciones `11 -> 48`.
17. Integridad de claves foráneas.

## Comandos ejecutados

```sh
node --check scripts/staging-fixtures.js
node --check scripts/load-staging-fixtures-local.js
node --check test/staging-fixtures.test.js
node --test test/staging-fixtures.test.js
npm test
git diff --check
```

También se ejecutó dos veces el comando real de carga contra la misma D1 local
persistente para validar la ruta operativa, no solo las funciones importadas.

## Resultados

- Pruebas específicas: 11/11 aprobadas.
- Suite completa backend: 95/95 aprobadas.
- Fallos: 0.
- `node --check`: correcto en los tres archivos.
- `git diff --check`: correcto.
- Segunda carga: cero inserciones nuevas.
- Advertencia: `punycode` de Wrangler/Node, preexistente y no bloqueante.

## Rendimiento

La prueba ampliada generó, insertó, verificó, recargó idempotentemente y analizó
5,000 resultados más 5,000 filas de cobertura. El subtest completo tardó
aproximadamente 10.2 segundos en este equipo y permaneció bajo el límite local
de 30 segundos. El límite es una guardia de regresión local, no un compromiso
de rendimiento de Cloudflare.
