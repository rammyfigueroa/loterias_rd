# Modelo estadístico

## Variables

Sea una secuencia verificada de eventos de una serie:

```text
E = (E_1, E_2, ..., E_n)
```

Cada evento tiene número `X_i`, fecha `D_i` e identidad estable. Para un número
origen `a`, una transición válida existe cuando `X_i = a`, existe `E_i+1`, ambos
eventos están dentro del rango y la continuidad cumple el modo de cobertura.

Para cada destino `b`:

```text
C(a,b) = cantidad de transiciones válidas a -> b
T(a)   = suma de C(a,b) para todos los destinos b
F(a,b) = C(a,b) / T(a), si T(a) > 0
```

`F(a,b)` es frecuencia relativa observada, no probabilidad futura.

## Unidades reportadas

- `originAppearances`: eventos dentro del rango cuyo número es `a`.
- `totalTransitions`: `T(a)` después del filtro de cobertura.
- `transitionCount`: `C(a,b)`.
- `relativeFrequency`: `F(a,b)` con precisión de al menos seis decimales en API.
- `lastTransitionDate`: fecha del evento destino más reciente para `a -> b`.
- `sampleSize`: sinónimo visible de `totalTransitions`; no mantener dos valores
  distintos.

La suma de todos los conteos debe ser exactamente `totalTransitions`; la suma
de frecuencias de la respuesta completa debe ser 1 dentro del error de redondeo.

## Rango

El subconjunto se forma antes de construir pares. Un evento previo a `from` no
se conecta con el primer evento del rango. El último evento dentro de `to` no se
conecta con un evento posterior. Esto hace que el cálculo sea reproducible a
partir del rango solicitado y evita información exterior invisible.

## Cobertura

- `verified`: denominador y conteos incluyen solo transiciones `VERIFIED`.
- `incomplete`: incluye solo transiciones `INCOMPLETE_COVERAGE` para auditoría.
- `all`: incluye ambas, pero reporta subtotales separados y una advertencia.

No imputar números ni redistribuir peso por fechas faltantes. Una fecha
`NO_DRAW_SCHEDULED` confirmada preserva continuidad porque no representa un
evento omitido.

## Empates y cero

Los empates se ordenan por número destino ascendente. Destinos con cero
transiciones no se incluyen en el ranking principal; la interfaz puede indicar
cuántos destinos distintos fueron observados. Si `T(a)=0`, la lista está vacía y
no se calcula porcentaje.

## Interpretación

Un porcentaje alto puede surgir por muestra pequeña o variación aleatoria. La
interfaz debe mostrar siempre `n`, rango, serie y cobertura. No usar términos
“jala”, “predice”, “probable”, “recomendado”, “fuerte” o “próximo”.

## Extensiones no incluidas

- intervalos de más de un evento;
- coaparición en el mismo sorteo;
- combinación de posiciones;
- comparación agregada entre series;
- inferencia causal o modelos predictivos;
- pruebas de significación y correcciones por comparaciones múltiples.

Estas extensiones requerirían una especificación independiente.
