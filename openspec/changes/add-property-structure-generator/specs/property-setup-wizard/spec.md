## MODIFIED Requirements

### Requirement: Step 2 — Creación rápida de secciones (modo quick)
El wizard SHALL ofrecer en Step 2 un modo quick de generación masiva de secciones mediante un `StructureTemplate` sugerido por el `property_type` de la propiedad, además del modo manual existente. El usuario SHALL poder ajustar `count` y `prefix` de cada nivel del template, y ejecutar un preview antes de confirmar. Los campos del `StructureTemplate` (`levels`, `units_per_leaf`, `identifier_format`) son exclusivos del modo quick y no aplican al modo manual.

#### Scenario: Selección de modo en Step 2
- **WHEN** el usuario está en Step 2 del wizard
- **THEN** puede elegir entre tres modos: `none` (sin secciones), `manual` (secciones libres individuales) y `quick` (generación masiva con preview/commit via API)

#### Scenario: Template sugerido cargado automáticamente en modo quick
- **WHEN** el usuario selecciona modo quick
- **THEN** el wizard carga el `StructureTemplate` sugerido para el `property_type` de la propiedad y pre-rellena los niveles, counts y prefijos

#### Scenario: Preview de secciones en modo quick
- **WHEN** el usuario ajusta los niveles del template (count y prefix por nivel) y solicita preview
- **THEN** el wizard muestra la lista de secciones que se crearán según la jerarquía del template (1 o 2 niveles), con indicación de duplicados y conflictos

#### Scenario: Preview no disponible en modo manual
- **WHEN** el usuario selecciona modo manual
- **THEN** el wizard muestra el formulario de secciones libres sin paso de preview; las secciones se crean de forma individual

#### Scenario: Confirmación de secciones en modo quick
- **WHEN** el usuario acepta el preview en modo quick
- **THEN** las secciones se crean y el wizard avanza al Step 3; el `StructureTemplate` (incluyendo `units_per_leaf`) queda disponible en el wizard state para Step 3

#### Scenario: Confirmación de secciones en modo manual
- **WHEN** el usuario completa las secciones en modo manual y avanza
- **THEN** el wizard avanza al Step 3 sin `StructureTemplate` en el wizard state

### Requirement: Step 3 — Modos disponibles según Step 2

El wizard SHALL determinar los modos de creación de unidades disponibles en Step 3 según el `structure_mode` del wizard state. El modo automático SHALL estar disponible únicamente cuando Step 2 fue completado en modo quick.

#### Scenario: Modos disponibles cuando Step 2 fue quick
- **WHEN** el usuario llega a Step 3 y `wizardState.structure_mode === 'quick'`
- **THEN** Step 3 ofrece tres modos: automático, importación y manual

#### Scenario: Modos disponibles cuando Step 2 fue manual o none
- **WHEN** el usuario llega a Step 3 y `wizardState.structure_mode` es `manual` o `none`
- **THEN** Step 3 ofrece solo dos modos: importación y manual; el modo automático no se muestra

### Requirement: Step 3 — Creación rápida de unidades (modo automático)
El wizard SHALL ofrecer en Step 3 generación masiva de unidades únicamente cuando Step 2 fue quick. `UnitsGeneratorForm` SHALL mostrar `units_per_leaf` e `identifier_format` del `StructureTemplate` como contexto no editable, heredados del wizard state de Step 2. Step 3 NO SHALL pedir `units_per_leaf` como campo editable.

#### Scenario: StructureTemplate heredado de Step 2 quick
- **WHEN** el usuario llega a Step 3 en modo automático (solo posible cuando Step 2 fue quick)
- **THEN** `UnitsGeneratorForm` muestra `units_per_leaf` e `identifier_format` como contexto no editable heredado del wizard state y solo pide tipo de unidad

#### Scenario: Contexto de estructura visible en Step 3
- **WHEN** el usuario llega a Step 3 con secciones creadas en modo quick
- **THEN** el wizard muestra como contexto no editable: niveles del template (section_types, counts) y `units_per_leaf`

#### Scenario: Preview de unidades en Step 3
- **WHEN** el usuario selecciona tipo de unidad y solicita preview
- **THEN** el wizard muestra la lista de unidades agrupadas por sección hoja, con estado de cada una (`:new`, `:duplicate`, `:conflict`)

#### Scenario: Confirmación de unidades en Step 3
- **WHEN** el usuario acepta el preview
- **THEN** las unidades se crean y el wizard continúa
