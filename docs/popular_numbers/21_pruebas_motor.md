# Pruebas del motor

## Ubicación

`loterias_rd_api/test/number-transitions.test.js`

Todos los fixtures son sintéticos y usan operadores, sorteos, fechas y números
creados exclusivamente para pruebas. No contienen tablas tradicionales ni
datos comerciales.

## Cobertura implementada

Las 26 pruebas aisladas cubren:

1. secuencia simple;
2. múltiples destinos;
3. autotransición;
4. orden de entrada invertido;
5. empate estable;
6. duplicado equivalente por identidad;
7. conflicto por identidad estable;
8. conflicto por fecha;
9. duplicado equivalente con IDs distintos;
10. corrección canónica;
11. evento sin resultado;
12. `NO_DRAW_SCHEDULED` verificado;
13. cobertura ausente;
14. `UNVERIFIED`;
15. `PENDING`;
16. `FETCH_FAILED`;
17. `NO_RESULTS_RETURNED`;
18. modos `incomplete` y `all`;
19. último evento sin sucesor;
20. origen inexistente;
21. serie vacía;
22. límites inclusivos e inexistencia de pares exteriores;
23. rango incompleto o invertido;
24. números, fechas, IDs, posiciones y estados inválidos;
25. mezcla de operador/sorteo y conflicto de cobertura;
26. precisión a seis decimales, determinismo y ausencia de lenguaje de
    recomendación o garantía.

## Comandos y resultados

```text
node --test test/number-transitions.test.js
26 pruebas, 26 aprobadas, 0 fallidas

node --check src/statistics/number-transitions.js
sin errores

node --check test/number-transitions.test.js
sin errores

npm test
63 pruebas, 63 aprobadas, 0 fallidas
```

La suite completa incluye las 26 pruebas nuevas y 37 pruebas backend
preexistentes de historial, proveedor, reintentos, rangos, cobertura,
estadísticas, aislamiento y paginación.

## Invariantes comprobadas

- El orden de entrada no cambia la salida.
- La suma de conteos coincide con el denominador.
- Una misma entrada produce exactamente la misma estructura.
- No se divide por cero.
- Los empates se ordenan por número ascendente.
- Una serie ajena causa error, no mezcla.
- Una discontinuidad no se trata como verificada.
- Los conflictos no se resuelven arbitrariamente.

## Pendientes para otra fase

- Pruebas de ruta HTTP, consulta D1, caché y paginación cuando esas capas sean
  autorizadas.
- Medición de rendimiento con volúmenes equivalentes al historial real, sin
  usar datos comerciales en fixtures versionados.
- Pruebas Flutter solo después de autorizar integración de interfaz.
