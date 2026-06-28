## ADDED Requirements

### Requirement: Preview de secciones
El sistema SHALL generar una previsualización de secciones a partir de un `StructureTemplate` sin escribir en base de datos (`PreviewSections`). La previsualización SHALL detectar duplicados con secciones existentes y conflictos internos dentro del batch.

#### Scenario: Preview de secciones con reglas válidas
- **WHEN** el usuario envía un `StructureTemplate` con niveles configurados
- **THEN** el sistema retorna una lista de secciones con su estado (`:new`, `:duplicate`, `:conflict`) y un resumen con totales

#### Scenario: Detección de duplicado de sección con existente
- **WHEN** el batch generado incluye una sección cuyo nombre ya existe en la propiedad
- **THEN** ese ítem aparece con estado `:duplicate` y NO se incluye en el conteo de nuevos

#### Scenario: Detección de conflicto interno en secciones
- **WHEN** dos secciones del mismo batch tienen el mismo nombre generado
- **THEN** ambas aparecen con estado `:conflict`

#### Scenario: PreviewSections no persiste datos
- **WHEN** se ejecuta `PreviewSections` con cualquier `StructureTemplate`
- **THEN** la base de datos no contiene secciones nuevas

### Requirement: Preview de unidades
El sistema SHALL generar una previsualización de unidades a partir de las secciones hoja existentes y el `StructureTemplate` sin escribir en base de datos (`PreviewUnits`). La previsualización SHALL detectar duplicados con unidades existentes y conflictos internos dentro del batch.

#### Scenario: Preview de unidades con reglas válidas
- **WHEN** el usuario envía las secciones hoja y el `StructureTemplate` (con `units_per_leaf` e `identifier_format`)
- **THEN** el sistema retorna una lista de unidades con su estado (`:new`, `:duplicate`, `:conflict`) y un resumen con totales

#### Scenario: Detección de duplicado de unidad con existente
- **WHEN** el batch generado incluye una unidad cuyo identificador ya existe en la propiedad
- **THEN** ese ítem aparece con estado `:duplicate` y NO se incluye en el conteo de nuevos

#### Scenario: Detección de conflicto interno en unidades
- **WHEN** dos unidades del mismo batch tienen el mismo identificador generado
- **THEN** ambas aparecen con estado `:conflict`

#### Scenario: PreviewUnits no persiste datos
- **WHEN** se ejecuta `PreviewUnits` con cualquier configuración
- **THEN** la base de datos no contiene unidades nuevas

### Requirement: Commit de secciones y unidades
El sistema SHALL persistir secciones (`CommitSections`) y unidades (`CommitUnits`) en transacciones independientes, cada una alineada con su step del wizard. Solo se persisten ítems con estado `:new`.

#### Scenario: Commit de secciones exitoso
- **WHEN** el usuario confirma el commit de secciones con un preview válido que contiene ítems nuevos
- **THEN** el sistema crea las secciones en la base de datos dentro de una transacción y registra un evento de auditoría del lote

#### Scenario: Commit de unidades exitoso
- **WHEN** el usuario confirma el commit de unidades con un preview válido que contiene ítems nuevos
- **THEN** el sistema crea las unidades en la base de datos dentro de una transacción y registra un evento de auditoría del lote

#### Scenario: Commit falla por unicidad concurrente
- **WHEN** entre el preview y el commit otro usuario creó una sección/unidad con el mismo nombre
- **THEN** el sistema hace rollback total de la transacción y retorna un error indicando que los datos cambiaron desde el preview; ningún registro queda persistido parcialmente

#### Scenario: CommitSections registra auditoría
- **WHEN** el commit de secciones se ejecuta exitosamente
- **THEN** queda registrado un evento de auditoría con el usuario, la propiedad, la cantidad de secciones creadas y el timestamp

#### Scenario: CommitUnits registra auditoría
- **WHEN** el commit de unidades se ejecuta exitosamente
- **THEN** queda registrado un evento de auditoría con el usuario, la propiedad, la cantidad de unidades creadas y el timestamp

### Requirement: StructureTemplate define la configuración de generación
El sistema SHALL usar un `StructureTemplate` como input principal para la generación. El template SHALL contener hasta 2 niveles de sección, cada uno con `section_type`, `count`, `prefix` y `suffix_type` (`:letter` o `:number`). El nivel hoja (último nivel) es donde se crean las unidades.

#### Scenario: Template de 2 niveles
- **WHEN** el template tiene niveles `[{tower, 2, "Torre"}, {floor, 10, "Piso"}]`
- **THEN** `GenerateSections` produce: Torre A > Piso 1...10, Torre B > Piso 1...10

#### Scenario: Template de 1 nivel
- **WHEN** el template tiene un solo nivel `[{floor, 12, "Piso"}]`
- **THEN** `GenerateSections` produce: Piso 1, Piso 2, ..., Piso 12 (secciones planas, sin padre)

### Requirement: StructureTemplateResolver sugiere template por property_type
El sistema SHALL proveer un template recomendado para cada `property_type`. El usuario puede ajustar `count`, `prefix` y `suffix_type` de cada nivel, pero no cambiar los `section_type`.

#### Scenario: Template sugerido para building
- **WHEN** la propiedad es de tipo `building`
- **THEN** el template sugerido tiene niveles `[tower, floor]` con unidades en `floor`; el usuario puede eliminar el nivel `tower` si el edificio no tiene torres, resultando en un template de 1 nivel `[floor]`

#### Scenario: Template sugerido para condominium horizontal
- **WHEN** la propiedad es de tipo `condominium`
- **THEN** el template sugerido tiene niveles `[sector, block]` con unidades en `block`

#### Scenario: Template sugerido para tower
- **WHEN** la propiedad es de tipo `tower`
- **THEN** el template sugerido tiene un solo nivel `[floor]` con unidades en `floor`

### Requirement: Generación de secciones desde StructureTemplate
El sistema SHALL generar secciones en memoria a partir del `StructureTemplate`. Cada nivel define su `suffix_type` (`:letter` o `:number`). El nombre de cada sección combina el `prefix` con el sufijo correspondiente.

#### Scenario: Secciones con sufijo letra
- **WHEN** el nivel tiene `prefix: "Torre"`, `count: 2`, `suffix_type: :letter`
- **THEN** los nombres generados son `Torre A`, `Torre B`

#### Scenario: Secciones con sufijo numérico
- **WHEN** el nivel tiene `prefix: "Torre"`, `count: 3`, `suffix_type: :number`
- **THEN** los nombres generados son `Torre 1`, `Torre 2`, `Torre 3`

#### Scenario: Sub-secciones generadas por nivel hijo
- **WHEN** el template tiene 2 niveles y el nivel padre produce `Torre A`, `Torre B`
- **THEN** cada padre genera sus hijos según el `count` y `suffix_type` del nivel hijo

### Requirement: Generación de unidades con tokens por section_type
El sistema SHALL generar identificadores interpolando tokens nombrados por `section_type` (`{tower}`, `{floor}`, `{sector}`, `{block}`) más `{number}`. El número usa padding configurable.

#### Scenario: Formato con 2 niveles
- **WHEN** el formato es `{tower}-{floor}{number}`, template `[tower×2, floor×3]`, 4 unidades por piso, padding 2
- **THEN** se generan: `A-0101`, `A-0102`, `A-0103`, `A-0104`, `A-0201`, ..., `B-0304`

#### Scenario: Formato con 1 nivel
- **WHEN** el formato es `{floor}{number}`, template `[floor×5]`, 4 unidades por piso, padding 2
- **THEN** se generan: `0101`, `0102`, `0103`, `0104`, `0201`, ..., `0504`

#### Scenario: Padding configurable
- **WHEN** el padding de número es 3
- **THEN** el número 1 se renderiza como `001`

### Requirement: Tenant isolation en generación y commit
El sistema SHALL scoping todas las operaciones de preview y commit a `Current.organization` y al `ResidentialProperty` indicado.

#### Scenario: Duplicados verificados por tenant
- **WHEN** una unidad con el mismo identificador existe en otra organización
- **THEN** NO se detecta como duplicado; el ítem aparece como `:new`

#### Scenario: Commit scoped al tenant
- **WHEN** el commit persiste registros
- **THEN** todos los registros creados tienen el `organization_id` del tenant actual

### Requirement: Autorización para generación y commit
El sistema SHALL permitir solo a usuarios con capacidad de administración de la propiedad ejecutar preview y commit.

#### Scenario: Acceso autorizado
- **WHEN** un `property_admin` o `tenant_admin` ejecuta preview o commit
- **THEN** la operación se ejecuta exitosamente

#### Scenario: Acceso denegado
- **WHEN** un usuario sin capacidad de administración intenta ejecutar preview o commit
- **THEN** el sistema responde con error 403
