## Context

El wizard de configuración de propiedad (`property-setup-wizard`) ya maneja la creación de secciones (Step 2) y unidades (Step 3) de forma manual. Para propiedades grandes (edificios con torres, pisos y cientos de unidades) la carga manual es impráctica. Se añade un generador declarativo que convierte reglas simples en listas de secciones/unidades, con un paso de previsualización obligatorio antes de persistir.

Los modelos `PropertySection` y `Unit` ya existen con sus validaciones y scoping multitenant. Los servicios nuevos operan sobre ellos sin alterar sus contratos públicos.

## Goals / Non-Goals

**Goals:**
- `StructureTemplate` como value object central; `StructureTemplateResolver` sugiere el template por `property_type`.
- Ocho servicios bajo `PropertySetup::`: `GenerateSections`, `GenerateUnits` (generadores en memoria), `PreviewSections`, `CommitSections` (Step 2), `PreviewUnits`, `CommitUnits` (Step 3).
- Tokens de formato por `section_type` (`{tower}`, `{floor}`, `{sector}`, `{block}`, `{number}`), mostrados dinámicamente en el UI.
- Máximo 2 niveles de sección por template.
- Flujo preview → commit: preview no toca DB, commit persiste en transacción con auditoría.
- Detección de duplicados (nombre de sección/unidad ya existente en la propiedad) y conflictos (colisiones dentro del batch generado).
- Integración con el wizard en Step 2 (generación rápida de secciones) y Step 3 (generación rápida de unidades).
- Soporte de formato de nombre parametrizable: `{tower}-{floor}-{number}` → `A-101`.

**Non-Goals:**
- Modificar o eliminar secciones/unidades existentes.
- Importar desde CSV/Excel.
- Generar occupancies, ownerships ni staff assignments.
- Formatos de nombre con regex arbitraria.

## Decisions

### 1. `StructureTemplate` como value object central

`StructureTemplate` encapsula la configuración de generación:

```ruby
StructureTemplate = Data.define(:levels, :units_per_leaf, :identifier_format)
# levels: array de hasta 2 elementos { section_type:, count:, prefix:, suffix_type: :letter | :number }
# units_per_leaf: cantidad de unidades en la sección hoja
# identifier_format: string con tokens {section_type_name}... {number}

# Ejemplos:
# building:     levels: [{tower, 2, "Torre"}, {floor, 10, "Piso"}], format: "{tower}-{floor}{number}"
# condominium:  levels: [{sector, 3, "Sector"}, {block, 4, "Bloque"}], format: "{sector}-{block}{number}"
# tower:        levels: [{floor, 12, "Piso"}], format: "{floor}{number}"
```

Todos los servicios de generación (`GenerateSections`, `GenerateUnits`) reciben un `StructureTemplate` como input principal. Esto los desacopla de la lógica de qué es una "torre" o un "piso".

### 2. `StructureTemplateResolver` sugiere el template por `property_type`

Dado el `property_type` de la propiedad, `StructureTemplateResolver` retorna el template recomendado. El usuario puede ajustar conteos y prefijos, y puede eliminar el nivel superior para reducir a 1 nivel. El resolver siempre retorna el template más rico disponible.

```ruby
PropertySetup::StructureTemplateResolver.for(property_type: 'building')
# → StructureTemplate con levels: [tower, floor]

PropertySetup::StructureTemplateResolver.for(property_type: 'condominium')
# → StructureTemplate con levels: [sector, block]
```

| property_type | nivel 1 | nivel 2 | unidades en | nota |
|---|---|---|---|---|
| `building` | `tower` | `floor` | floor | si no hay torres el usuario elimina el nivel 1; queda solo `floor` |
| `tower` | `floor` | — | floor | |
| `condominium` horizontal | `sector` | `block` | block | |
| `condominium` vertical | `sector` | `tower` | tower | |
| `horizontal_community` | `sector` | `block` | block | |
| `residential_complex` | `tower` | `floor` | floor | |
| `sector` | `block` | — | block | |
| `mixed_use` | `tower` | `floor` | floor | |
| `other` | `block` | — | block | |

### 3. Tokens de formato por `section_type`, mostrados dinámicamente en el UI

El formato de identificador usa tokens nombrados por `section_type`: `{tower}`, `{floor}`, `{sector}`, `{block}`, más `{number}` siempre disponible. El UI muestra los tokens según los niveles del template activo con botones de inserción. El `identifier_format` por defecto viene en el `StructureTemplate`; el usuario puede modificarlo.

**Alternativa considerada**: tokens posicionales `{l1}`, `{l2}`. Rechazada porque `{sector}-{block}101` es semánticamente opaco; `{tower}-{floor}{number}` habla del dominio.

**Alternativa considerada**: DSL estructurado. Rechazada por mayor complejidad sin beneficio práctico para los casos de uso actuales.

### 4. Máximo 2 niveles de sección

La tabla de property types muestra que todos los casos se cubren con 1 o 2 niveles. Limitar a 2 simplifica `GenerateSections`, el UI del wizard, y los tokens de formato. Estructuras de 3+ niveles no existen en el dominio actual.

### 5. Servicios puros en memoria para generación

`GenerateSections` y `GenerateUnits` retornan arrays de structs sin tocar DB. Son los únicos que conocen las reglas declarativas (tokens, padding, prefijos). `PreviewSections` y `PreviewUnits` los consumen y agregan detección de duplicados consultando DB solo para comparar.

**Alternativa considerada**: un único servicio monolítico. Rechazada porque mezcla generación, validación y persistencia, dificultando tests unitarios.

### 6. Preview y Commit divididos por entidad, alineados con el wizard

`PreviewSections` / `CommitSections` sirven al Step 2. `PreviewUnits` / `CommitUnits` sirven al Step 3. Los generadores son reutilizados por cada par.

```
Step 2                          Step 3
──────────────────────          ──────────────────────
PreviewSections                 PreviewUnits
 └─ GenerateSections             └─ GenerateUnits
 └─ detecta duplicados           └─ detecta duplicados

CommitSections                  CommitUnits
 └─ insert_all secciones         └─ insert_all unidades
 └─ auditoría del batch          └─ auditoría del batch
```

**Alternativa considerada**: `PreviewStructure` + `CommitStructure` monolíticos. Rechazada porque el wizard separa la confirmación de secciones (Step 2) de la de unidades (Step 3).

### 7. Dos pares de endpoints REST, uno por step

`Admin::Properties::SectionsGeneratorController` → `preview` + `commit` (Step 2).
`Admin::Properties::UnitsGeneratorController` → `preview` + `commit` (Step 3).

**Alternativa considerada**: un único controller con cuatro acciones. Rechazada; controllers por recurso son más fáciles de autorizar y testear de forma aislada.

### 8. Rollback total en commit ante unicidad concurrente

Si entre el preview y el commit otro usuario crea una sección o unidad con el mismo nombre/identificador, `CommitSections` o `CommitUnits` hacen rollback total de la transacción. El usuario recibe un error claro y puede repetir el flujo.

**Alternativa considerada**: commit parcial. Rechazada porque genera estado parcial difícil de comunicar en la UX. Las race conditions son excepcionales; el costo de repetir el preview es bajo.

### 9. Contratos JSON de preview por entidad

`PreviewSections` retorna `{ sections: [...{ name:, status: }], summary: { total:, new:, duplicates:, conflicts: } }`.
`PreviewUnits` retorna `{ units: [...{ identifier:, section_name:, status: }], summary: { total:, new:, duplicates:, conflicts: } }`.

### 10. `SectionsGeneratorForm` reemplaza la implementación del modo `quick` existente

El modo `quick` de Step 2 ya existe con inputs similares. El generador nuevo unifica esos campos en un `StructureTemplate` y hace preview y commit vía API en lugar de solo client-side. No se añade un cuarto modo.

**Alternativa considerada**: cuarto modo `generator` coexistiendo con `quick`. Rechazada porque crearía confusión en la UX sin beneficio.

### 11. Modo automático en Step 3 solo disponible cuando Step 2 fue quick

Cuando Step 2 fue manual o none, las secciones son heterogéneas y el generador no puede determinar a qué sección asociar cada unidad. El modo automático no se muestra (ni deshabilitado).

```
Step 2 quick  → Step 3: automático + importación + manual
Step 2 manual → Step 3: importación + manual
Step 2 none   → Step 3: importación + manual
```

**Alternativa considerada**: mostrar el modo deshabilitado con tooltip. Rechazada porque añade ruido visual para un caso que el usuario no puede resolver sin volver al Step 2.

### 12. `units_per_leaf` siempre heredado en `UnitsGeneratorForm`

`UnitsGeneratorForm` solo aparece cuando Step 2 fue quick, que siempre captura `units_per_leaf` en el `StructureTemplate`. Por lo tanto `units_per_leaf` se muestra siempre como contexto no editable — sin lógica condicional.

### 13. Límite máximo de unidades por batch configurable por organización

El número máximo de unidades generables en un solo commit es configurable por organización (no hardcodeado). `PreviewUnits` valida que el batch no exceda el límite y retorna un error si lo supera, antes de consultar duplicados. El límite por defecto se define en configuración de la aplicación.

### 14. Nombres de sección con sufijo numérico o letra, configurable por nivel

`GenerateSections` soporta dos modos de sufijo por nivel: letras (A, B, C...) o números (1, 2, 3...). El tipo de sufijo es configurable en el `StructureTemplate` por nivel (`suffix_type: :letter | :number`). El prefijo se combina con el sufijo: "Torre A" / "Torre 1", "Piso 1" / "Piso A".

### 15. Auditoría mediante `audited` gem en tabla `audits` existente

Los commits de secciones y unidades registran eventos de auditoría en la tabla `audits` existente de la gem `audited`. Como `insert_all` no dispara callbacks, la auditoría se registra manualmente mediante `Audited::Audit.create!` con `action: 'bulk_create'`, `auditable_type`, `user`, y metadata del lote (count, property_id).

## Risks / Trade-offs

- **Lotes muy grandes (500+ unidades)** → `PreviewUnits` puede ser lento por la consulta de duplicados. Mitigación: paginar o limitar el tamaño del lote en la primera iteración; optimizar con una sola query `WHERE identifier IN (...)`.
- **Race condition entre preview y commit** → si otro usuario crea secciones o unidades entre preview y commit, el commit puede fallar por unicidad. Mitigación: `CommitSections` y `CommitUnits` re-validan duplicados dentro de la transacción y hacen rollback total; el usuario recibe un error claro y puede repetir el preview.
- **`insert_all` y auditoría**: `audited` gem no intercepta `insert_all`. Mitigación: registrar un `Audited::Audit` manualmente con `action: 'bulk_create'` indicando el lote y el usuario (decisión 15).

## Migration Plan

No hay migraciones de schema nuevas. Las tablas `property_sections` y `units` ya existen. Se añaden solo archivos de servicio, controller, rutas y frontend.

Rollout:
1. Merging los servicios y el controller (sin ruta expuesta aún).
2. Habilitar rutas y frontend detrás de la navegación del wizard.
3. No hay rollback especial; los registros creados por commit son estándar y el wizard manual sigue disponible.
