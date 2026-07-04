## MODIFIED Requirements

### Requirement: Step 3 defines how units will be created

Step 3 SHALL let the user choose how units for the property will be created and persisted during this step.

Supported modes:

1. create a single unit;
2. create multiple units automatically, using the structure from step 2 — available **only** when step 2 used quick mode;
3. import units from Excel through the existing bulk import flow.

Automatic generation is gated to quick mode: when step 2 was manual or none, the automatic option SHALL NOT be offered and the user is directed to single creation or import. When quick mode was used, automatic generation applies the established identifier-format rules (`floor_sequential` / `block_sequential` / `sequential`, `units_per_leaf`) derived from the active `PropertyStructureFormat` (`units_in`).

Automatic generation SHALL create units distributed one batch per leaf section resolved from `PropertyStructureFormat#units_in` (e.g. one batch per floor for buildings/towers, one batch per block for condominiums/horizontal/sector properties), not a single flat batch of unsectioned units. Each generated unit SHALL use the `unit_type` and `identifier_format` configured for this generation, not implementation-hardcoded defaults. The preview shown before generating and the units actually persisted SHALL be produced by the same leaf-resolution and identifier-format logic, so the preview accurately represents what will be created.

`identifier_format` SHALL produce identifiers as follows, for `index` ranging over `0..units_per_leaf-1` within each leaf section:
- `floor_sequential`: `"#{leaf.position * 100 + index + 1}"` (e.g. floor 1 → `101, 102, ...`; floor 2 → `201, 202, ...`).
- `block_sequential`: `"B#{leaf.position * 100 + index + 1}"` (e.g. block 1 → `B101, B102, ...`; block 2 → `B201, B202, ...`).
- `sequential`: `"#{index + 1}"`, reset at the start of every leaf section (not continuous across the whole property).

`units_per_leaf` is the only parameter name for the per-leaf quantity; it SHALL be honored by both the preview and the persisted generation.

The step MUST show contextual information from previous steps, including property name and structure summary when available.

#### Scenario: Automatic generation is available only for quick structures

- **GIVEN** step 2 used quick mode and produced a hierarchical structure
- **WHEN** the user opens step 3
- **THEN** they may choose to generate units automatically from that structure
- **AND** configuration fields such as unit type, identifier format, and units per leaf are available
- **AND** a live preview shows sample generated unit identifiers

#### Scenario: Automatic generation is unavailable for manual and none modes

- **GIVEN** step 2 used manual or none mode
- **WHEN** the user opens step 3
- **THEN** the automatic generation mode is not offered
- **AND** the user is directed to single creation or import

#### Scenario: Single unit creation is available for simple cases

- **GIVEN** the user chooses individual unit creation
- **WHEN** they provide valid unit data
- **THEN** the unit is persisted via `Units::Create` on the draft property
- **AND** the unit is associated with the draft property and optional section

#### Scenario: Excel import reuses existing bulk import behavior

- **GIVEN** the user chooses import from Excel
- **WHEN** they upload or select a file through the wizard
- **THEN** validation and parsing reuse the existing bulk import contract for units
- **AND** the wizard surfaces import errors, warnings and duplicates without duplicating domain rules in the client

#### Scenario: Unit step shows estimated creation summary

- **GIVEN** the user configured unit generation for 80 units
- **WHEN** the auxiliary summary renders
- **THEN** it states how many units will be created
- **AND** it explains the calculation basis when generation is automatic

#### Scenario: Unit validation errors are shown without losing wizard state

- **GIVEN** one or more units or import rows are invalid
- **WHEN** the user attempts to continue
- **THEN** the wizard remains on step 3
- **AND** errors, warnings or duplicates are shown per item or row
- **AND** previously persisted units and setup data remain intact

#### Scenario: Automatic generation distributes units per leaf section

- **GIVEN** step 2 produced a quick structure with multiple leaf sections (e.g. 2 towers x 3 floors)
- **AND** step 3 is configured with `units_per_leaf: 4`
- **WHEN** automatic generation runs
- **THEN** each leaf section receives its own batch of 4 units
- **AND** every generated unit references its resolved leaf `property_section_id`
- **AND** no generated unit is created without a section when leaf sections exist

#### Scenario: Automatic generation honors configured unit type and identifier format

- **GIVEN** step 3 is configured with `unit_type: office` and `identifier_format: block_sequential`
- **WHEN** automatic generation runs against block-leaf sections
- **THEN** every generated unit has `unit_type: office`
- **AND** identifiers follow the `block_sequential` numbering rule for each block

#### Scenario: block_sequential identifiers are position-based and start at B1

- **GIVEN** step 3 is configured with `identifier_format: block_sequential` and `units_per_leaf: 2`
- **AND** the structure has block sections at position 1 and position 2
- **WHEN** automatic generation runs
- **THEN** the block at position 1 receives identifiers `B101, B102`
- **AND** the block at position 2 receives identifiers `B201, B202`

#### Scenario: sequential identifiers reset per leaf section

- **GIVEN** step 3 is configured with `identifier_format: sequential` and `units_per_leaf: 3`
- **AND** the structure has two leaf sections
- **WHEN** automatic generation runs
- **THEN** each leaf section receives identifiers `1, 2, 3`
- **AND** numbering does not continue across leaf sections

#### Scenario: Preview and persisted units match

- **GIVEN** the step 3 preview shows a set of projected unit identifiers grouped by leaf section
- **WHEN** the user confirms and automatic generation persists units
- **THEN** the persisted units match the previewed identifiers and leaf placement

#### Scenario: Preview honors the configured per-leaf quantity

- **GIVEN** the user configures `units_per_leaf: 8`
- **WHEN** the step 3 preview (client-side or server-side) renders
- **THEN** it shows 8 projected units per leaf section
- **AND** no other parameter name silently overrides the configured quantity

#### Scenario: Automatic-mode form defaults to the property's actual leaf format on first render

- **GIVEN** a property whose resolved leaf level is `block` (e.g. `condominium`, `horizontal`, `sector`)
- **WHEN** the user opens step 3 for the first time or resumes an in-progress wizard on this property
- **THEN** the automatic-generation form's `identifier_format` defaults to `block_sequential`
- **AND** it does not default to `floor_sequential`, which is not a valid option for this property's leaf format

### Requirement: Each step validates before progression

The wizard MUST validate the active step before allowing forward navigation or final confirmation.

Validation rules MUST reuse existing domain contracts for property, section and unit data rather than inventing parallel client-only rules.

#### Scenario: Invalid property step blocks step 2

- **GIVEN** step 1 has validation errors
- **WHEN** the user attempts to continue
- **THEN** step 2 is not opened
- **AND** the errors remain visible on step 1

#### Scenario: Invalid structure option blocks step 3

- **GIVEN** the selected structure mode is incomplete or inconsistent
- **WHEN** the user attempts to continue from step 2
- **THEN** step 3 is not opened
- **AND** the user receives step-level errors or empty-state guidance

#### Scenario: Invalid units block summary progression

- **GIVEN** step 3 contains blocking unit or import errors
- **WHEN** the user attempts to continue to step 4
- **THEN** the wizard remains on step 3
- **AND** blocking errors are identified explicitly

#### Scenario: Summary blocks confirmation while blocking issues remain

- **GIVEN** step 4 still contains blocking errors
- **WHEN** the user attempts to continue to confirmation
- **THEN** progression is blocked
- **AND** the summary indicates which sections require correction

#### Scenario: Automatic generation failure blocks step advancement

- **GIVEN** the user submits step 3 in automatic mode
- **AND** unit creation fails for at least one planned unit (e.g. an authorization or validation error)
- **WHEN** the wizard attempts to advance to step 4
- **THEN** the wizard remains on step 3
- **AND** the failure is surfaced as a visible error
- **AND** the wizard's recorded current step is not advanced

### Requirement: Wizard delegates all domain operations to existing services

Each wizard step MUST use the existing domain services and policies for property, section and unit operations. No domain rule is duplicated in the wizard layer.

- Step 1 persists the property via `Properties::Setup::InitializeDraft`.
- Steps 2 and 3 create sections and units via `PropertySections::Create` and `Units::Create`.
- Step 5 transitions the property via `Properties::Setup::Confirm` → `Properties::Setup::Configure`.

The wizard SHALL NOT bypass `ResidentialProperty`, `PropertySection`, `Unit` or bulk import authorization and validation rules.

#### Scenario: Property initialization uses domain contract

- **WHEN** the wizard completes Step 1 and advances
- **THEN** `Properties::Setup::InitializeDraft` creates the property with `status = draft`
- **AND** property normalization, uniqueness and lifecycle rules from `residential-property` are enforced
- **AND** the property is scoped to the current organization

#### Scenario: Section creation uses domain contract

- **GIVEN** the user adds sections in Step 2
- **WHEN** each section is created
- **THEN** `PropertySections::Create` is invoked on the draft property
- **AND** hierarchy, naming and eligibility rules from `property-section` are enforced
- **AND** every section belongs to the draft property in the current organization

#### Scenario: Unit creation and import use domain contract

- **GIVEN** the user creates or imports units in Step 3
- **WHEN** each unit is created
- **THEN** `Units::Create` or the existing bulk import path is invoked on the draft property
- **AND** identifier normalization, uniqueness and section eligibility rules from `unit` are enforced

#### Scenario: Automatic generation invokes Units::Create per leaf section

- **GIVEN** automatic generation is running for a property with resolved leaf sections
- **WHEN** each planned unit is created
- **THEN** `Units::Create` is invoked with the unit's resolved leaf `property_section_id`
- **AND** section eligibility and uniqueness rules from `unit` are enforced per leaf, exactly as for manually created units

### Requirement: Step 4 presents an editable review summary

Before final confirmation, the wizard MUST show a clear summary of everything configured in prior steps.

The summary SHALL include:

* the persisted property (status `draft`);
* sections already created, when applicable;
* units already created or imported;
* errors;
* warnings;
* detected duplicates;
* omitted items, when applicable.

The summary MUST allow the user to return to earlier steps to correct information.

Structure counts shown in the step 3/4 summary SHALL be derived from the property's resolved `PropertyStructureFormat` (top level and `units_in` leaf level), not from hardcoded `tower`/`floor` section types, so properties using other formats (e.g. `sector`/`block`) show accurate, non-zero counts. Any unit `code` shown in the summary SHALL be the derived hierarchical code (`unit.code`), not the raw `identifier`.

#### Scenario: Summary shows top-level cards and detailed sections

- **GIVEN** the user reaches step 4 with a valid draft property, sections and units
- **WHEN** the summary renders
- **THEN** top-level cards show property, structure, units and address at a glance
- **AND** detailed sections expand property data, structure tree and a units preview table

#### Scenario: Summary reflects warnings and duplicates

- **GIVEN** the setup contains non-blocking warnings or duplicate candidates
- **WHEN** the summary renders
- **THEN** warnings and duplicates are visible in the review
- **AND** the user can distinguish blocking errors from non-blocking issues

#### Scenario: User can navigate back from summary to fix data

- **GIVEN** the user identifies incorrect structure or units in the summary
- **WHEN** they go back to an earlier step and change data
- **THEN** the summary reflects the current state of the draft property, its sections and units

#### Scenario: Summary shows informational notice before confirmation

- **GIVEN** the user is reviewing a valid setup
- **WHEN** step 4 renders
- **THEN** an informational notice explains that sections and units may still be adjusted after confirmation through ordinary administration flows

#### Scenario: Summary shows correct structure counts for non-floor formats

- **GIVEN** a `condominium` property with 2 `sector` sections and 6 `block` sections
- **WHEN** the step 3/4 summary renders
- **THEN** the top-level count reflects the 2 sectors
- **AND** the leaf-level count reflects the 6 blocks
- **AND** neither count is reported as `0`

#### Scenario: Summary shows the derived unit code, not the raw identifier

- **GIVEN** a unit with `identifier: "101"` and derived `code: "clp-tor-torre-a-piso-1-101"`
- **WHEN** the unit appears in the step 3/4 summary preview rows
- **THEN** the row's code field shows `"clp-tor-torre-a-piso-1-101"`
- **AND** not the raw `identifier` value
