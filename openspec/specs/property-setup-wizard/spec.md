# property-setup-wizard

## Purpose

Defines the guided five-step property setup wizard: authorization to start the flow, the step-by-step layout (property data, structure, units, review, confirmation), incremental draft persistence, per-step validation via existing domain services, and the `draft → configured → active` property lifecycle.

## Requirements

### Requirement: Authorized users can start the property setup wizard

The system SHALL expose a guided property setup flow for creating a complete residential property configuration from scratch.

Only users with the organizational capability to manage properties in the current organization SHALL be able to start or confirm the wizard.

#### Scenario: Tenant admin starts wizard

- **GIVEN** an authenticated tenant administrator in organization O
- **WHEN** they open the new property setup entry point
- **THEN** the wizard loads at step 1
- **AND** the flow is scoped to organization O

#### Scenario: Unauthorized user is denied

- **GIVEN** an authenticated user without property-management capability in organization O
- **WHEN** they attempt to open or confirm the wizard
- **THEN** access is denied
- **AND** no draft setup state is created for them

#### Scenario: Cross-organization access is denied

- **GIVEN** a user operates in organization O
- **WHEN** they attempt to resume or confirm a setup draft belonging to organization Q
- **THEN** access is denied
- **AND** no records are created or updated in Q

### Requirement: Wizard presents a five-step guided layout

The wizard UI SHALL follow the observable layout contract derived from the reference mockups `create-property-step-1.png` through `create-property-step-5.png`.

The layout MUST include:

* a persistent page title and short description explaining that this is a guided setup flow;
* a horizontal stepper with exactly five steps labeled for property data, structure, units, summary and confirmation;
* a main content area for the active step;
* an auxiliary panel when the reference flow shows contextual preview or summary information;
* a footer action area with navigation controls.

The stepper MUST distinguish the current step, completed steps and pending steps.

#### Scenario: Step 1 shows property data layout

- **GIVEN** the user is on step 1
- **WHEN** the wizard renders
- **THEN** the stepper highlights "Datos de la propiedad" as the current step
- **AND** the main area shows the property data form
- **AND** an auxiliary "Resumen inicial" panel reflects the entered values as they become available

#### Scenario: Completed steps are marked in the stepper

- **GIVEN** the user has completed steps 1 and 2
- **WHEN** they view step 3
- **THEN** steps 1 and 2 appear as completed in the stepper
- **AND** step 3 appears as the current step
- **AND** steps 4 and 5 appear as pending

#### Scenario: Footer exposes primary and secondary actions per step

- **GIVEN** the user is on any wizard step except the first
- **WHEN** the footer renders
- **THEN** a secondary "Atrás" action is available to return to the previous step
- **AND** a secondary "Cancelar" action is available to exit the flow
- **AND** a primary forward action is available when the current step is valid

### Requirement: Step 1 captures basic property data

Step 1 SHALL collect the minimum property data needed to continue the guided setup.

Required fields (persisted on `ResidentialProperty`):

* property name;
* property type;
* address.

Wizard planning field (UX only, not persisted as a domain column):

* estimated unit count — used to populate the Step 1 summary panel and inform the user's planning; it is not stored on `ResidentialProperty`.

Optional fields:

* extensible metadata in key-value form.

The step MUST communicate that this is the beginning of a guided configuration, not an isolated property form.

#### Scenario: Valid property data allows continuation

- **GIVEN** the user enters a valid name, property type and address
- **WHEN** they choose to continue
- **THEN** the wizard advances to step 2
- **AND** the entered values remain available in later steps

#### Scenario: Missing required property data blocks continuation

- **GIVEN** one or more required fields are blank or invalid
- **WHEN** the user attempts to continue
- **THEN** the wizard remains on step 1
- **AND** field-level validation errors are shown

#### Scenario: Initial summary panel reflects entered property data

- **GIVEN** the user has entered property type, address and estimated units
- **WHEN** the auxiliary summary panel renders
- **THEN** it shows the current type, location summary and estimated unit count
- **AND** it shows a flow status indicating that structure is still pending

#### Scenario: Optional metadata does not block progression

- **GIVEN** required property fields are valid
- **WHEN** optional metadata is left empty
- **THEN** the user may continue to step 2

### Requirement: Step 2 defines optional property structure

Step 2 SHALL let the user choose how the property internal structure will be defined. The available structure modes and form fields SHALL be derived from the `property_type` selected in step 1.

The user MUST be able to choose exactly one of:

1. no sections;
2. manual hierarchical structure (a free-form builder constrained to the two-level model, guided by the recommended format);
3. quick repetitive structure generation (form fields determined by the active format).

In manual mode the wizard SHALL provide a full structure builder that lets the user create, rename, and delete sections, choose each section's type and parent, and see the tree update live in the shared preview panel. The builder SHALL enforce the existing hierarchy rules (max two levels; a section with children cannot hold units; units attach only to leaf sections) by delegating to `PropertySections::Create` and the section-removal use case, surfacing model validation errors rather than bypassing them.

The wizard SHALL load the recommended `PropertyStructureFormat` for the `property_type` and pass it to step 2 as a prop. The format defines up to 2 section levels and the target level for units (`units_in`).

#### Scenario: No sections skips hierarchical structure

- **GIVEN** the user selects "Sin secciones"
- **WHEN** they continue
- **THEN** the wizard records that units will belong only to the property
- **AND** step 3 does not require section placement for generated units

#### Scenario: Manual structure builder creates, edits, and removes sections

- **GIVEN** the user selects "Crear estructura manual"
- **WHEN** they add root sections and child sections
- **THEN** each section is persisted via `PropertySections::Create` on the draft property and shown in the live preview
- **AND** the wizard shows a warning when the created `section_type` does not match the recommended format for the `property_type`
- **AND** the user may rename or delete sections before continuing, with deletions guarded by the existing dependent-section/unit rules

#### Scenario: Manual builder rejects a third hierarchy level

- **GIVEN** a root section that already has a child section
- **WHEN** the user attempts to add a section under that child
- **THEN** the operation is rejected with the two-level validation message
- **AND** the persisted structure is unchanged

#### Scenario: Quick structure form adapts to active format

- **GIVEN** the user selects "Crear estructura rápida"
- **WHEN** the active format has 2 levels (e.g., tower/floor)
- **THEN** the form shows inputs for level 1 count, level 2 count per level 1, and prefix for each level
- **AND** when the active format has 1 level (e.g., floor-only or block-only), the form shows only count and prefix for that level
- **AND** the quick mode option is not shown when the property type has no mapped format

#### Scenario: Quick structure preview must be confirmed before continuing

- **GIVEN** the user configures quick structure parameters
- **WHEN** the preview is shown
- **THEN** the user can review the sections that will be created, including names and hierarchy
- **AND** the preview shows counts and detects duplicates or conflicts with existing sections
- **AND** the user must confirm the generated structure before advancing

#### Scenario: building allows removing the tower level

- **GIVEN** the `property_type` is `building` and step 2 shows the tower/floor format
- **WHEN** the user disables the "¿El edificio tiene torres?" toggle
- **THEN** the active format switches to floor-only
- **AND** the quick structure form adapts to show only floor count and prefix

#### Scenario: Structure step shows preview panel in all modes

- **GIVEN** the user is in step 2 in any mode (none, manual, or quick)
- **WHEN** the step renders
- **THEN** a preview panel is always visible showing the current structure state
- **AND** in none mode it shows an empty state; in manual mode it reflects persisted sections live; in quick mode it shows the in-memory generated batch
- **AND** the panel renders sections only — units are not present in step 2 and the panel handles their absence without error

#### Scenario: Step 3 reuses the same preview panel with units

- **GIVEN** the user is in step 3 in automatic generation mode
- **WHEN** a unit batch has been generated in memory
- **THEN** the same preview panel component renders sections and units nested under their leaf section
- **AND** when no units have been generated yet the panel shows only sections

#### Scenario: Empty manual structure blocks continuation

- **GIVEN** the user chose manual structure
- **WHEN** no section has been added
- **THEN** continuation is blocked
- **AND** an empty-state message explains that structure is required for this option

#### Scenario: Changing property_type in step 1 resets step 2 format

- **GIVEN** the user configured step 2 with a structure
- **WHEN** the user navigates back to step 1 and changes `property_type`
- **THEN** the active format in step 2 is recalculated for the new type
- **AND** previously configured structure values are discarded
- **AND** a notice informs the user that the structure configuration was reset

### Requirement: Step 3 defines how units will be created

Step 3 SHALL let the user choose how units for the property will be created and persisted during this step.

Supported modes:

1. create a single unit;
2. create multiple units automatically, using the structure from step 2 — available **only** when step 2 used quick mode;
3. import units from Excel through the existing bulk import flow.

Automatic generation is gated to quick mode: when step 2 was manual or none, the automatic option SHALL NOT be offered and the user is directed to single creation or import. When quick mode was used, automatic generation applies the established identifier-format rules (`floor_sequential` / `block_sequential` / `sequential`, `units_per_leaf`) derived from the active `PropertyStructureFormat` (`units_in`).

If no active `PropertyStructureFormat` can be resolved for the property type, automatic generation SHALL be unavailable and SHALL NOT create a flat unsectioned fallback batch.

Automatic generation SHALL create units distributed one batch per leaf section resolved from `PropertyStructureFormat#units_in` (e.g. one batch per floor for buildings/towers, one batch per block for condominiums/horizontal/sector properties), not a single flat batch of unsectioned units. Each generated unit SHALL use the `unit_type` and `identifier_format` configured for this generation, not implementation-hardcoded defaults. The preview shown before generating and the units actually persisted SHALL be produced by the same leaf-resolution and identifier-format logic, so the preview accurately represents what will be created.

`identifier_format` SHALL produce identifiers as follows, for `index` ranging over `0..units_per_leaf-1` within each leaf section:
- `floor_sequential`: `"#{leaf.position * 100 + index + 1}"` (e.g. floor 1 -> `101, 102, ...`; floor 2 -> `201, 202, ...`).
- `block_sequential`: `"B#{leaf.position * 100 + index + 1}"` (e.g. block 1 -> `B101, B102, ...`; block 2 -> `B201, B202, ...`).
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

#### Scenario: Estimated summary is structure-aware whenever a leaf level exists, regardless of the top level

- **GIVEN** the property's resolved structure has at least one leaf-level section (per `PropertyStructureFormat#units_in`)
- **AND** the top level has zero sections (single-level format, or a two-level format with the top level skipped)
- **WHEN** the auxiliary summary renders
- **THEN** it computes the structure-aware total (`leaf count x units_per_leaf`) and explanation
- **AND** it does not fall back to the flat/estimated total merely because the top-level count is zero

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

#### Scenario: block_sequential identifiers are position-based and start at B101 for position 1

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

#### Scenario: Automatic generation is unavailable without a resolved format

- **GIVEN** the property type has no recommended `PropertyStructureFormat`
- **WHEN** the user opens step 3
- **THEN** automatic generation is not offered
- **AND** no unsectioned fallback batch is generated automatically

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

Structure counts shown in the step 3/4 summary SHALL be derived from the property's resolved `PropertyStructureFormat` (top level and `units_in` leaf level), not from hardcoded `tower`/`floor` section types, so properties using other formats (e.g. `sector`/`block`) show accurate, non-zero counts. For a property whose resolved format has a single level (the level and the leaf are the same `section_type`), the summary SHALL report that level's count once and SHALL NOT report the same sections twice under two different counts. A resolved two-level format whose top level has no persisted sections (e.g. a "no towers" building) SHALL still report an accurate leaf-level count; the summary's structure-aware presentation SHALL NOT depend on the top-level count being greater than zero. Any unit `code` shown in the summary SHALL be the derived hierarchical code (`unit.code`), not the raw `identifier`.

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

#### Scenario: Summary counts a single-level structure once, not twice

- **GIVEN** a `tower` property (single-level format, leaf sections are `floor`) with 5 floor sections and no units yet
- **WHEN** the step 3/4 summary renders
- **THEN** the structure count for the floor level is `5`
- **AND** no other count also reports `5` for the same set of sections

#### Scenario: Summary shows accurate leaf count when the top level was skipped

- **GIVEN** a `building` property created with the "no towers" quick-structure option (`skip_top_level`), with 6 floor sections at the root and no tower sections
- **WHEN** the step 3/4 summary renders
- **THEN** the leaf-level (floor) count is `6`
- **AND** the top-level (tower) count is `0`
- **AND** the summary still presents the structure-aware unit estimate and explanation, not the flat/estimated fallback

### Requirement: Step 5 confirms setup and then shows completion actions

Step 5 SHALL first present a pre-confirmation state before transitioning the property from `draft` to `configured`. The property, its sections and its units are already persisted from prior steps; confirmation commits the lifecycle transition.
After successful confirmation, the same step SHALL transition to a completion state with next actions.

The screen MUST include:

* a ready-to-confirm state explaining that the property setup is ready to be finalized;
* a checklist of prepared elements;
* a compact final count summary;
* an auxiliary panel describing what will happen upon confirmation;
* an explicit confirmation control that requires user acknowledgment.

After successful confirmation, the system MUST show a completion state with clear next actions.

Suggested next actions:

* go to property detail;
* manage units;
* import owners;
* configure residents.

#### Scenario: Confirmation requires explicit acknowledgment

- **GIVEN** the user is on step 5
- **WHEN** the confirmation acknowledgment is not checked
- **THEN** the final confirm action remains disabled or rejected

#### Scenario: Successful confirmation transitions property to configured

- **GIVEN** the user confirms a valid setup draft
- **WHEN** the confirmation completes successfully
- **THEN** the draft property transitions from `status = draft` to `status = configured`
- **AND** all sections and units previously created during the wizard remain associated to the property
- **AND** the user sees a success completion state

#### Scenario: Completion screen offers next actions

- **GIVEN** setup confirmation succeeded
- **WHEN** the completion state renders
- **THEN** the user can navigate to the created property detail
- **AND** the user can continue with unit administration
- **AND** the user can start owner import
- **AND** the user can continue resident configuration

#### Scenario: Confirmation failure preserves draft for correction

- **GIVEN** the status transition fails due to a domain validation or authorization error
- **WHEN** confirmation is attempted
- **THEN** the property remains in `status = draft` with its sections and units intact
- **AND** the user receives actionable errors
- **AND** they may return to earlier steps or retry confirmation after correction

### Requirement: Wizard state is persisted incrementally and safely

The system SHALL persist wizard progress incrementally as the user advances through steps.

Step 1 completion persists the `ResidentialProperty` with `status = draft`. Steps 2 and 3 create `PropertySection` and `Unit` records directly on that draft property through existing domain services. Final confirmation transitions the property to `status = configured`.

The client MUST NOT be treated as the source of truth for `organization_id`, property ownership or cross-entity relationships.

#### Scenario: Step 1 persists property as draft

- **GIVEN** the user completes valid property data in step 1
- **WHEN** they continue to step 2
- **THEN** a `ResidentialProperty` record is created with `status = draft`
- **AND** the property is scoped to the authenticated organization

#### Scenario: Navigating back preserves earlier step data

- **GIVEN** the user completed steps 1 through 3
- **WHEN** they return to step 1 or 2 and then move forward again
- **THEN** previously entered values remain available
- **AND** dependent previews are recalculated from the current persisted draft state

#### Scenario: Wizard can be resumed after interruption

- **GIVEN** the user started the wizard and left it in progress
- **WHEN** they return to the setup flow later
- **THEN** the draft property and its configured sections and units are restored
- **AND** the wizard resumes at the last incomplete step

#### Scenario: Cancel on a draft property prompts the user to choose

- **GIVEN** the wizard is in progress and the property has `status = draft`
- **WHEN** the user presses Cancel
- **THEN** a confirmation modal is shown asking whether to delete the draft or keep it for later
- **AND** if the user chooses to delete, the draft property and its sections and units are removed and the user is returned to the properties index
- **AND** if the user chooses to keep, no records are modified and the user is returned to the properties index with the draft intact

#### Scenario: Cancel on a configured or active property returns to index

- **GIVEN** the wizard is open for a property with `status = configured` or `status = active`
- **WHEN** the user presses Cancel
- **THEN** the user is returned to the properties index without any destructive action

#### Scenario: Client cannot force organization ownership

- **GIVEN** a setup payload includes `organization_id` or foreign keys from another organization
- **WHEN** any wizard step is submitted or confirmed
- **THEN** the system ignores or rejects client-supplied organization ownership
- **AND** all created records belong to the authenticated organization context

#### Scenario: Refresh or resume keeps authorized draft scope

- **GIVEN** an authorized user resumes an in-progress setup
- **WHEN** the wizard state is restored
- **THEN** only their tenant-scoped draft property is accessible
- **AND** another organization's draft is not accessible

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

#### Scenario: Structure changes are blocked after automatic units exist

- **GIVEN** automatic generation has already created units for a draft property
- **WHEN** the user returns to step 2 and attempts to regenerate or replace the quick structure
- **THEN** the destructive structure change is blocked until generated units are explicitly cleared through the supported draft cleanup path
- **AND** the system does not silently move, delete, or orphan existing units

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

#### Scenario: Automatic generation idempotency uses normalized identifiers

- **GIVEN** a planned unit would normalize to `normalized_identifier: "area-4"` in leaf section S
- **AND** a non-deleted unit already exists in S with the same `normalized_identifier`
- **WHEN** automatic generation is retried
- **THEN** the existing unit is treated as the planned row for idempotency
- **AND** no duplicate unit is created from a visually different but equivalent identifier

#### Scenario: Existing matching unit with different type is reported

- **GIVEN** a planned unit has `unit_type: office`
- **AND** a non-deleted matching unit already exists in the same leaf section with the same normalized identifier but a different `unit_type`
- **WHEN** automatic generation is retried
- **THEN** the existing unit is not overwritten
- **AND** a non-blocking warning is surfaced for review

### Requirement: Wizard UI text is fully internationalized

All user-visible wizard text MUST be internationalized in `es`, `en` and `pt`.

This includes step titles, descriptions, empty states, validation messages, summary labels, confirmation copy and next-action labels.

#### Scenario: Wizard renders in current locale

- **GIVEN** the application locale is `es`, `en` or `pt`
- **WHEN** any wizard step renders
- **THEN** visible text comes from i18n keys
- **AND** no hardcoded user-facing literals are shown

### Requirement: Property lifecycle progresses from draft to configured to active

A property created through the setup wizard SHALL follow a defined lifecycle that separates setup in progress, setup complete, and fully operational states.

| Status | Meaning | Mutable by section and unit services |
| --- | --- | --- |
| `draft` | Wizard in progress | Yes |
| `configured` | Wizard completed, pending explicit activation | Yes |
| `active` | Fully operational | Yes |
| `inactive` | Temporarily suspended | No |
| `archived` | Permanently retired | No |

Properties in `draft` and `configured` status SHALL be visible in the administrative property catalog for all users with permission to list properties, with a visible status badge distinguishing them from `active` properties.

Explicit activation from `configured` to `active` is a separate administrative action performed after wizard completion.

Editing a `configured` property does not revert it to `draft`.

#### Scenario: Draft property is visible in catalog with badge

- **GIVEN** a property exists with `status = draft`
- **WHEN** an authorized user views the property catalog
- **THEN** the draft property appears in the list
- **AND** a visual badge indicates its draft status

#### Scenario: Configured property is visible in catalog with badge

- **GIVEN** a property exists with `status = configured`
- **WHEN** an authorized user views the property catalog
- **THEN** the configured property appears in the list
- **AND** a visual badge distinguishes it from active properties

#### Scenario: Explicit activation transitions configured to active

- **GIVEN** a property has `status = configured`
- **WHEN** an authorized user performs the explicit activation action
- **THEN** the property transitions to `status = active`
- **AND** it becomes fully operational for all domain flows

#### Scenario: Draft and configured properties accept section and unit mutations

- **GIVEN** a property is in `draft` or `configured` status
- **WHEN** domain services for sections or units are invoked on it
- **THEN** the operations are accepted
- **AND** the property lifecycle gate does not block setup operations

#### Scenario: Inactive and archived properties reject mutations

- **GIVEN** a property is in `inactive` or `archived` status
- **WHEN** domain services for sections or units are invoked on it
- **THEN** the operations are rejected with a property lifecycle error

### Requirement: Reference mockups define the UX contract without prescribing pixel styling

The implementation MUST follow the functional and informational layout implied by:

* `mockups/improve-property-setup-flow/create-property-step-1.png`
* `mockups/improve-property-setup-flow/create-property-step-2.png`
* `mockups/improve-property-setup-flow/create-property-step-3.png`
* `mockups/improve-property-setup-flow/create-property-step-4.png`
* `mockups/improve-property-setup-flow/create-property-step-5.png`

The contract covers step hierarchy, content distribution between main and auxiliary panels, navigation affordances, preview behavior, summary structure and completion actions.

It does NOT require reproducing exact colors, spacing values or component styling beyond what is needed to satisfy the observable UX behavior.

#### Scenario: Step 2 matches option-card interaction model

- **GIVEN** the user is on the structure step
- **WHEN** structure mode options are shown
- **THEN** the three options are presented as mutually exclusive choices with title and helper description
- **AND** selecting one option reveals only the configuration controls relevant to that mode

#### Scenario: Step 3 matches method-selection and preview model

- **GIVEN** the user is on the units step
- **WHEN** unit creation methods are shown
- **THEN** the user selects one primary creation method at a time
- **AND** the main form and preview panel update according to the selected method

#### Scenario: Step 5 matches confirmation and consequence panel model

- **GIVEN** the user is on the confirmation step
- **WHEN** the screen renders
- **THEN** the main area shows readiness checklist and final counts
- **AND** the auxiliary panel explains the consequences of confirming
- **AND** the primary action is labeled as final confirmation, distinct from ordinary step continuation

### Requirement: Step 3 supports manual section-level unit management

Step 3 SHALL provide a new `manual` unit management mode for draft properties. The mode SHALL use the same visual tree pattern already used by `ManualSectionForm` and `ManualSectionTreeRow`, with units rendered under their assigned section when present.

The manual mode requires at least one eligible section to exist; eligible section rows SHALL expose only an add-unit action, and ineligible section rows SHALL NOT show the add-unit action. Unit creation, edit, and deletion SHALL remain scoped to the current draft property and organization and require the property-scoped `manage_units` permission.

#### Scenario: Manual unit view reuses section preview

- **GIVEN** a draft property has persisted sections from step 2
- **WHEN** the user opens step 3 manual unit management
- **THEN** the step renders the same visual tree pattern used by `ManualSectionForm` and `ManualSectionTreeRow`
- **AND** any existing non-deleted units are shown beneath their assigned section

#### Scenario: Section rows expose only add-unit action

- **GIVEN** the user is viewing sections in step 3 manual unit management
- **WHEN** an eligible section row renders
- **THEN** it exposes an add-unit action
- **AND** it does not expose edit-section, add-child-section, or delete-section actions

#### Scenario: Ineligible section rows do not expose add-unit

- **GIVEN** a section cannot contain units according to the property-section contract
- **WHEN** the section row renders in manual unit mode
- **THEN** no add-unit action is shown for that section
- **AND** the user is not invited to submit a unit for that section

#### Scenario: Add-unit opens individual and multiple options

- **GIVEN** the user triggers add-unit from an eligible section
- **WHEN** the creation dialog opens
- **THEN** it offers individual and multiple creation modes
- **AND** created units are assigned to that section through the draft property's server-side context

#### Scenario: Ineligible section cannot receive units

- **GIVEN** a request references a section that is not eligible to contain units according to the property-section contract
- **WHEN** the server processes the unit creation
- **THEN** the mutation is rejected
- **AND** no unit is created or silently assigned elsewhere

#### Scenario: Manual unit mutations refresh preview

- **GIVEN** the user creates, edits, or deletes a unit in step 3
- **WHEN** the mutation succeeds
- **THEN** the response is used to refresh the persisted unit data shown in the preview
- **AND** the preview reflects the persisted non-deleted units without losing wizard state

#### Scenario: Automatic is default for new quick setup

- **GIVEN** a draft property reaches step 3 for the first time
- **AND** step 2 used quick structure
- **WHEN** no units mode has been persisted yet
- **THEN** the wizard selects automatic mode by default

#### Scenario: Manual is default when editing or resuming units

- **GIVEN** a draft property returns to step 3 after units have already been created or the units step has already been persisted
- **WHEN** the wizard renders the units step
- **THEN** manual mode is selected by default
- **AND** the user can switch to automatic or import when those modes are available

#### Scenario: Cross-organization unit mutation is denied

- **GIVEN** the user is operating in organization O
- **WHEN** a step 3 unit mutation references a property, section, or unit from organization Q
- **THEN** access is denied
- **AND** no foreign data is returned or mutated

#### Scenario: User without manage_units is denied

- **GIVEN** a user is authorized to run setup for draft property P
- **AND** the user lacks `manage_units` for P
- **WHEN** they attempt to create, edit, or soft-delete a unit through the setup wizard
- **THEN** authorization is denied
- **AND** no unit is created, edited, or deleted

### Requirement: Summary and confirmation use persisted wizard data

The setup wizard SHALL render step 4 summary and step 5 confirmation from the current persisted database state for the authorized draft property. Property details, section counts, unit counts, and visible nested summaries MUST be derived from records scoped to the current organization and residential property, not from client-side estimates, previous form state, or partial generation previews.

Deleted sections and soft-deleted units MUST be excluded from ordinary visible summary and confirmation totals. Units associated with soft-deleted sections MUST NOT be counted or shown, even when the unit itself is not soft-deleted. The summary and confirmation views MUST use the same persisted data contract so the user reviews and confirms the same counts.

The setup wizard MUST NOT ask for, require, or display an estimated unit count as a property data input, and step 1 validation MUST NOT block submission on an estimated unit count. Unit totals shown in summary, confirmation, and the post-confirmation completed view SHALL represent persisted non-deleted units associated with eligible property sections. No wizard prop contract, at any step, SHALL retain an "estimated unit count" field once a persisted count is available.

#### Scenario: Summary unit total matches persisted units

- **GIVEN** an authorized user is setting up draft property P in organization O
- **AND** P has 24 non-deleted persisted units associated with eligible sections
- **WHEN** the user opens the step 4 summary
- **THEN** the unit total shown in the summary is 24
- **AND** the total is not replaced by an estimated unit count or by the number of units in a partial preview

#### Scenario: Confirmation unit total matches summary

- **GIVEN** the step 4 summary for draft property P shows 24 non-deleted persisted units associated with sections
- **WHEN** the user opens the step 5 confirmation
- **THEN** the confirmation view shows the same 24-unit total
- **AND** the confirmation view does not recompute a different total from stale client state

#### Scenario: Property data summary reflects saved property fields

- **GIVEN** draft property P has saved name, type, address, status, structure, and unit records
- **WHEN** the step 4 summary renders "Datos de la propiedad"
- **THEN** the displayed property data reflects P's persisted values
- **AND** structure and unit totals are derived from P's current non-deleted persisted associations

#### Scenario: Estimated unit input is not shown

- **GIVEN** an authorized user opens the property data step
- **WHEN** the property data form renders
- **THEN** no estimated unit count input is shown
- **AND** no later summary, confirmation, or completed value is derived from an estimated unit count

#### Scenario: Property data step submits without an estimated unit count

- **GIVEN** an authorized user completes the property data step
- **WHEN** the user submits step 1 without an estimated unit count value
- **THEN** step 1 validation does not require or block on an estimated unit count
- **AND** the draft property is saved successfully

#### Scenario: Completed view shows the same persisted totals as confirmation

- **GIVEN** the step 5 confirmation for draft property P shows a 24-unit persisted total
- **WHEN** the user confirms and the wizard renders the completed view
- **THEN** the completed view shows the same 24-unit persisted total
- **AND** the completed view does not read or display an estimated unit count

#### Scenario: Summary excludes records outside the current property

- **GIVEN** organization O has draft property P with 24 non-deleted persisted units associated with sections
- **AND** organization O has another property Q with additional units
- **WHEN** the user opens P's step 4 summary or step 5 confirmation
- **THEN** only units belonging to P are counted
- **AND** Q's units are not included

#### Scenario: Summary preserves tenant isolation

- **GIVEN** draft property P belongs to organization O
- **AND** another organization Q has properties, sections, and units
- **WHEN** an authorized user in organization O opens P's summary or confirmation
- **THEN** no property, section, or unit data from organization Q is counted or displayed

#### Scenario: Soft-deleted units are excluded

- **GIVEN** draft property P has 24 non-deleted persisted units associated with sections
- **AND** P has 2 soft-deleted units
- **WHEN** the user opens the summary or confirmation
- **THEN** the ordinary visible unit total is 24
- **AND** the soft-deleted units are not shown in the nested unit preview

#### Scenario: Units under soft-deleted sections are excluded

- **GIVEN** draft property P has 24 non-deleted persisted units associated with non-deleted sections
- **AND** P has a soft-deleted section containing 3 non-deleted units
- **WHEN** the user opens the summary or confirmation
- **THEN** the ordinary visible unit total is 24
- **AND** the units under the soft-deleted section are not shown in the nested unit preview

#### Scenario: Summary refreshes after step 3 mutations

- **GIVEN** an authorized user creates, edits, or soft-deletes units in step 3
- **WHEN** the user navigates to the step 4 summary
- **THEN** the summary reflects the persisted result of those mutations
- **AND** stale pre-mutation counts are not shown

#### Scenario: Soft-delete reduces persisted unit totals

- **GIVEN** draft property P has 24 non-deleted persisted units associated with sections
- **WHEN** an authorized user soft-deletes one unit in step 3 and opens the summary
- **THEN** the ordinary visible unit total is 23
- **AND** the confirmation view shows the same 23-unit total

#### Scenario: Confirmation reloads persisted totals independently

- **GIVEN** the step 4 summary for draft property P shows 24 non-deleted persisted units associated with sections
- **AND** the persisted unit total changes to 23 before confirmation renders
- **WHEN** the user opens the step 5 confirmation
- **THEN** the confirmation view reads the current persisted total
- **AND** the confirmation view shows 23 units instead of reusing stale step 4 state
