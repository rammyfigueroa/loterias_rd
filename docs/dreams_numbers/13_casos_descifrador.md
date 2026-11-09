# Casos lingüísticos para el futuro descifrador

No son resultados de una función implementada. Cada salida esperada muestra
trazabilidad y evita producir números no documentados.

## CD-01 — Coincidencia simple

**Entrada:** “Soñé con una culebra.”

- Concepto: DP-001; fragmento: `culebra`; polaridad: afirmativa.
- Asociaciones: `08` (S01) y conflicto relacionado `67` para víbora (S04).
- Salida editorial: mostrar fuentes y conflicto; no recomendar jugada.

## CD-02 — Dominicanismo documentado

**Entrada:** “Me soñé con un maco.”

- Concepto: DP-003; fragmento: `maco`; polaridad: afirmativa.
- Sentido probable: batracio, pero debe permitir desambiguación porque S15
  documenta sentidos figurados dominicanos.
- Asociación: `43` (S01), permiso pendiente.

## CD-03 — Intensificador

**Entrada:** “Soñé con mucha agua.”

- Concepto: DP-004; fragmento: `agua`; modificador de cantidad: `mucha`.
- Asociación: `01` (S01, S04).
- No inferir inundación sin evidencia adicional en el relato.

## CD-04 — Frase compuesta

**Entrada:** “Soñé con un muerto que me hablaba.”

- Conceptos candidatos: DP-007 y DP-008.
- La secuencia completa `muerto ... hablaba` favorece DP-008 sin ocultar que se
  detectó `muerto`.
- Asociación compuesta: `48` (S01, S04). No devolver automáticamente las
  asociaciones conflictivas del muerto simple como equivalentes.

## CD-05 — Relación, no sinonimia

**Entrada:** “Soñé con una mata de mango.”

- Concepto: DP-015; fragmento: `mata de mango`; entidad específica: mango.
- Asociaciones publicadas: `59` para planta/mata en S01/S04.
- `Árbol` no debe sustituir automáticamente a `mata`; mostrar coincidencia y
  relación semántica con confianza limitada.

## CD-06 — Negación

**Entrada:** “Soñé que no había ninguna culebra.”

- Concepto mencionado: DP-001; marcadores: `no`, `ninguna`.
- Polaridad: negada. Resultado: término reconocido, asociación no activada por
  defecto; explicar que la presencia fue negada.

## CD-07 — Ambigüedad léxica

**Entrada:** “Había un maco en el trato.”

- `Maco` puede significar batracio o sentido figurado de problema/trampa según
  S15. Sin contexto onírico y animal suficiente, solicitar selección de sentido.
- No producir `43` automáticamente.

## CD-08 — Fenómenos relacionados

**Entrada:** “El río creció, pero no se inundó la casa.”

- Conceptos: DP-012 `río` afirmado; DP-006 `inundación` negada; DP-013 `casa`
  mencionada como lugar.
- No convertir `creció` en `crecida` automáticamente sin una regla contextual
  revisada. No asignar número a casa.

## CD-09 — Múltiples símbolos

**Entrada:** “Vi un caballo junto al río y después comenzó a llover.”

- DP-011 caballo (`24`, S01/S04), DP-012 río (`21`, S01; conflicto S04) y DP-005
  lluvia (`39`, S01/S04).
- Mostrar tres coincidencias separadas, ordenadas por aparición y con fuentes.

## CD-10 — Sin correspondencia

**Entrada:** “Soñé que arreglaba una computadora.”

- No existe ficha piloto aplicable.
- Resultado: “Sin correspondencia documental en el catálogo revisado”, sin
  inferir profesión, objeto parecido ni número.

## Reglas derivadas para revisión futura

Tokenizar conservando posiciones; reconocer frases discontinuas limitadas;
registrar negación por alcance; diferenciar mención de activación; no propagar
números por hiperónimos; devolver `source_id`, fragmento y estado de derechos;
y permitir respuesta “sin correspondencia”.
