## Why

Administrar propiedades grandes implica crear decenas o cientos de secciones y unidades manualmente, lo que es propenso a errores y lento. Las propiedades tienen estructuras muy distintas según su tipo: un edificio usa torre → piso, un condominio horizontal usa sector → bloque, una torre simple usa piso directo. Este cambio permite generar secciones y unidades automáticamente desde un **StructureTemplate** sugerido por el tipo de propiedad, con un paso de previsualización antes de confirmar escritura.

## What Changes

- Abstracción `StructureTemplate`: define hasta 2 niveles de sección, el `section_type` de cada nivel, y los tokens de formato de identificador por `section_type`.
- Templates predefinidos por `property_type` (building, condominium, tower, etc.) sugeridos automáticamente en el wizard.
- Nuevos servicios bajo `PropertySetup::` para generar secciones y unidades desde un `StructureTemplate`.
- Flujo **preview → commit**: primero se muestra qué se creará (sin escribir en DB), luego se confirma.
- Detección de duplicados y conflictos en la fase de preview.
- Integración con el wizard de configuración de propiedad (Step 2 generación rápida y Step 3 desde unidades).
- Auditoría de los registros creados.

## Capabilities

### New Capabilities

- `property-structure-generator`: Generación masiva de secciones y unidades desde reglas declarativas con flujo preview/commit.

### Modified Capabilities

- `property-setup-wizard`: El wizard incorpora el generador como opción de creación rápida en Step 2 y Step 3.

## Impact

**Bounded context**: Property Setup · Property Sections · Units

**Modelos afectados**: `PropertySection`, `Unit`, `ResidentialProperty`

**Servicios nuevos**:
- `PropertySetup::StructureTemplate` — value object con niveles, section_types, tokens de formato y `units_per_leaf`.
- `PropertySetup::StructureTemplateResolver` — retorna el template sugerido dado un `property_type`.
- `PropertySetup::GenerateSections` — genera secciones en memoria desde un `StructureTemplate`.
- `PropertySetup::GenerateUnits` — genera unidades en memoria desde las leaf sections y el template.
- `PropertySetup::PreviewSections` / `PropertySetup::PreviewUnits` — detectan duplicados/conflictos sin persistir.
- `PropertySetup::CommitSections` / `PropertySetup::CommitUnits` — persisten en transacción con auditoría.

**Tablas**: `property_sections`, `units` (sin migraciones nuevas)

**Controladores / rutas**: `SectionsGeneratorController` y `UnitsGeneratorController` bajo `resources :properties`.

**Frontend**: integración en el wizard de configuración de propiedad (Vue pages).

**Tenant isolation**: toda operación está scoped a `Current.organization` y al `ResidentialProperty` correcto.

**Authorization**: requiere capability de administración de la propiedad.

## Non-goals

- No genera occupancies, ownerships ni asignaciones de staff.
- No importa desde CSV/Excel (eso es bulk import).
- No soporta más de 2 niveles de sección en el generador quick.
- No soporta formatos de nombre arbitrarios con regex; solo tokens por `section_type`.
- No modifica secciones o unidades existentes (solo crea nuevas).
