# Casos lingüísticos originales sin asociaciones numéricas

Estos ejemplos documentan comportamiento esperado para revisión. No son
resultados predictivos ni activan contenido real.

| ID | Entrada original | Fenómeno | Resultado documental esperado | Estado |
|---|---|---|---|---|
| CL-01 | “Soñé con un maco en el patio.” | Dominicanismo y polisemia | Detectar `maco`; solicitar sentido animal o figurado | `review` |
| CL-02 | “Había un maco en ese negocio.” | Sentido figurado | No asumir animal; marcar ambigüedad contextual | `review` |
| CL-03 | “No vi ningún maco.” | Negación | Reconocer mención negada; no activar interpretación | `review` |
| CL-04 | “La guagua nunca llegó.” | Negación y término regional | Detectar transporte; conservar `nunca` | `review` |
| CL-05 | “Soñé que esperaba una guagua.” | Contexto onírico | Detectar concepto sin asignarle significado cultural | `review` |
| CL-06 | “Caminé hasta el conuco.” | Voz contextual | Detectar candidato; pedir contexto si hay varios sentidos | `review` |
| CL-07 | “No entré al conuco porque llovía.” | Dos conceptos y negación | Conuco negado como destino; lluvia afirmada | `review` |
| CL-08 | “Había una mata de mango.” | Frase compuesta | Mantener `mata de mango`; no sustituir por árbol | `review` |
| CL-09 | “La mata no tenía hojas.” | Negación de atributo | Concepto presente; atributo negado | `review` |
| CL-10 | “Cayó un aguacero muy fuerte.” | Intensificación | Detectar fenómeno e intensidad; no inferir inundación | `review` |
| CL-11 | “Llovió, pero no fue un aguacero.” | Contraste y negación | Lluvia afirmada; aguacero negado | `review` |
| CL-12 | “La crecida no alcanzó la casa.” | Evento relacionado | Detectar crecida y casa; no convertir en inundación | `review` |
| CL-13 | “El río creció y después bajó.” | Verbo frente a sustantivo | No convertir automáticamente `creció` en `crecida` | `review` |
| CL-14 | “Recordé a un difunto de mi familia.” | Término sensible | Detectar sin generar interpretación sobre familia o muerte | `review` |
| CL-15 | “No era un difunto, era una fotografía.” | Corrección discursiva | Marcar primera lectura como negada/corregida | `review` |
| CL-16 | “Vi un becerro detrás de una vaca.” | Hipónimo y entidad adulta | Mantener dos conceptos relacionados, no sinónimos | `review` |
| CL-17 | “Una culebra cruzó cerca del conuco.” | Múltiples símbolos | Separar ambos conceptos en orden de aparición | `review` |
| CL-18 | “Tal vez era una culebra o una rama.” | Incertidumbre | Marcar alternativas y baja confianza | `review` |
| CL-19 | “La palabra romo apareció sin contexto.” | Acepción no verificada | No resolver sentido; solicitar aclaración | `review` |
| CL-20 | “Soñé que reparaba una computadora.” | Sin ficha | Responder sin correspondencia documental | `review` |

## Reglas

Conservar posiciones, negación, incertidumbre y frases compuestas. Las relaciones
semánticas no propagan interpretaciones y ningún caso devuelve números.
