# Casos de prueba

Todos los números y fechas siguientes son fixtures sintéticos.

## Motor

1. **Secuencia normal:** `10,20,10,30` produce `10->20=1`, `10->30=1`,
   `T(10)=2`, frecuencias `0.5` y `0.5`.
2. **Autotransición:** `10,10` produce `10->10=1`; no excluirla.
3. **Último evento:** `20,10` produce `originAppearances(10)=1` y `T(10)=0`.
4. **Origen ausente:** lista vacía, conteos cero y estado de muestra vacía.
5. **Serie vacía:** respuesta 200 vacía con cobertura disponible nula.
6. **Orden de entrada:** filas desordenadas generan el mismo resultado después
   de ordenar por fecha e ID.
7. **Duplicado idéntico:** se deduplica y no crea transición adicional.
8. **Duplicado conflictivo:** error; no elegir un valor arbitrariamente.
9. **Mezcla de serie:** cualquier fila con otro operador o sorteo se rechaza.
10. **Número inválido:** fila distinta de dos dígitos se rechaza.
11. **Fecha faltante verificada:** un día `NO_DRAW_SCHEDULED` entre eventos
    conserva transición verificada.
12. **Fecha faltante desconocida:** falta de cobertura marca transición
    incompleta y la excluye del modo `verified`.
13. **Estado bloqueante:** probar `UNVERIFIED`, `FETCH_FAILED`, `PENDING` y
    `NO_RESULTS_RETURNED` individualmente.
14. **Corrección:** cambiar un evento intermedio actualiza las dos transiciones
    adyacentes y el fingerprint.
15. **Frecuencias:** suma de conteos igual a `T(a)` y frecuencias completas
    cercanas a 1.
16. **Empate:** mismo conteo se ordena por número ascendente.

## Rangos

17. **Límites inclusivos:** eventos exactamente en `from` y `to` cuentan.
18. **Origen anterior a Desde:** no se conecta con el primer evento del rango.
19. **Destino posterior a Hasta:** no se conecta con el último evento del rango.
20. **Un solo evento:** cero transiciones.
21. **Rango invertido:** HTTP 400.
22. **Solo Desde o solo Hasta:** HTTP 400.
23. **Hasta futuro:** HTTP 400 usando fecha de Santo Domingo.
24. **Rango fuera de cobertura UI:** controlador muestra error antes de pedir.
25. **Rango con cobertura parcial:** metadatos y advertencia consistentes.

## API y D1

26. **Filtros obligatorios:** faltan operador, sorteo, posición o número.
27. **Posición no admitida:** `second` devuelve 400.
28. **Número canónico:** `0` se normaliza a `00` o se rechaza consistentemente,
    según decisión de implementación; probar contrato elegido.
29. **Serie no autorizada:** HTTP 400 sin consulta cruzada.
30. **D1 ausente:** HTTP 503.
31. **Paginación:** páginas sin duplicados ni omisiones; cursor inválido da 400.
32. **Orden estable:** conteo descendente y número ascendente.
33. **Consulta parametrizada:** no interpolar valores del usuario en SQL.
34. **Caché:** misma huella reutiliza; nuevo resultado, cobertura o revisión
    invalida; una nueva fecha dominicana actualiza `asOfDate`.
35. **Costo:** fixture grande verifica límites de tiempo y memoria sin cambiar
    resultados.

## Flutter

36. Selector de una sola serie; no ofrecer “Ambas”.
37. Selector 00-99 y formato con cero inicial.
38. Reutilización de `Desde`, `Hasta`, `Todo el historial` y `Aplicar fechas`.
39. Cambio de serie, número o rango limpia resultados anteriores.
40. Respuesta tardía no aparece bajo filtros nuevos.
41. Estados loading, vacío, error, reintento y datos.
42. Conteos y porcentajes coinciden con fixture de API.
43. Cobertura incompleta muestra advertencia y no se disfraza de verificada.
44. Diseño responsive sin desbordamiento en anchos soportados.
45. Semántica accesible para selectores, tabla y aviso.
46. El texto visible dice “frecuencia observada” y contiene descargo; no usa
    lenguaje predictivo.

## Regresión

47. Endpoints actuales de intervalos y números no cambian.
48. Filtros actuales envían `from/to` en todas las páginas.
49. Lotería Nacional y Gana Más siguen aisladas.
50. Feature flag de Sueños y Números permanece desactivada.
