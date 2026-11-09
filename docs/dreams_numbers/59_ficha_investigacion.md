# Ficha de investigación

## Modelo

| Campo | Regla |
|---|---|
| `record_id` | ID único sin datos personales, por ejemplo `ir_000001` |
| `association_id` | ID de la observación símbolo-número |
| `number` | Cadena `00`-`99`; vacío si la persona no indicó número |
| `symbol_original` | Forma expresada por la fuente, solo si su registro está autorizado |
| `symbol_normalized` | Término editorial posterior; nunca sustituye el original |
| `description` | Paráfrasis neutral del contexto |
| `source_id` | ID anónimo de participante o ID bibliográfico |
| `evidence_type` | `oral_testimony`, `family_transmission`, `document`, `publication`, `other` |
| `recorded_date` | Fecha ISO `YYYY-MM-DD` |
| `remembered_since` | Período declarado, aproximado o `unknown` |
| `context` | Sueño, acontecimiento, conversación u otro contexto declarado |
| `declared_geography` | País/provincia/municipio solo al nivel consentido |
| `family_transmission` | `yes`, `no`, `unknown`; sin identificar familiares |
| `immediate_origin` | Familiar, amistad, publicación, medio, personal, desconocido u otro |
| `common_source_group` | ID para agrupar registros que derivan de una misma fuente |
| `consent_status` | `not_collected`, `limited`, `granted`, `withdrawn` |
| `consent_version` | Versión del formulario aceptado |
| `verification_status` | `unverified`, `supported`, `disputed`, `verified`, `rejected` |
| `rights_status` | `unknown`, `permissionPending`, `authorized`, `restricted`, `rejected` |
| `editorial_status` | `draft`, `review`, `approved`, `rejected` |
| `independence_status` | `unknown`, `independent`, `shared_source`, `dependent`, `duplicate` |
| `review_references` | IDs de revisiones culturales, editoriales y jurídicas |
| `notes` | Observaciones sin datos personales innecesarios |

## Ejemplo estructural vacío

```json
{
  "record_id": "ir_000001",
  "association_id": "ia_000001",
  "number": null,
  "symbol_original": null,
  "symbol_normalized": null,
  "description": "",
  "source_id": "participant_anon_0001",
  "evidence_type": "oral_testimony",
  "recorded_date": null,
  "remembered_since": "unknown",
  "context": "",
  "declared_geography": null,
  "family_transmission": "unknown",
  "immediate_origin": "unknown",
  "common_source_group": null,
  "consent_status": "not_collected",
  "consent_version": null,
  "verification_status": "unverified",
  "rights_status": "unknown",
  "editorial_status": "draft",
  "independence_status": "unknown",
  "review_references": [],
  "notes": ""
}
```

El ejemplo no representa un testimonio real ni una asociación.

## Minimización y separación

La tabla de investigación no debe contener nombres, firmas, teléfonos,
direcciones, coordenadas precisas, documentos de identidad ni nombres de
familiares. Si el consentimiento firmado requiere identidad, debe conservarse
en un sistema separado y protegido, relacionado mediante un código restringido
que no se exporta al catálogo de investigación.

## Retiro y correcciones

Un retiro cambia `consent_status` a `withdrawn`, bloquea todo uso posterior y
activa el procedimiento humano de eliminación o conservación legalmente
requerida que se defina antes de recopilar datos. Las correcciones deben crear
una nueva versión y preservar el historial autorizado.
