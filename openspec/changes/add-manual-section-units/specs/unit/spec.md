## ADDED Requirements

### Requirement: Manual wizard unit creation supports individual and multiple modes

The system SHALL allow authorized step 3 users to create units manually from an eligible section using individual or multiple creation modes. Both modes MUST delegate each persisted unit to `Units::Create` and enforce tenant isolation, property scoping, section eligibility, identifier normalization, and uniqueness.

Multiple creation SHALL present a preview before persistence and MUST NOT create units whose submitted identifiers collide with non-deleted units in the same section context.

#### Scenario: Individual mode creates one unit in selected section

- **GIVEN** an authorized user selects add-unit on eligible section S in draft property P
- **WHEN** they submit valid individual unit data
- **THEN** exactly one unit is persisted through `Units::Create`
- **AND** the unit belongs to P, organization O, and section S

#### Scenario: Multiple mode creates units in selected section

- **GIVEN** an authorized user selects add-unit on eligible section S
- **WHEN** they confirm a valid multiple-unit preview
- **THEN** each unit is persisted through `Units::Create`
- **AND** each unit belongs to S and uses the submitted unit type and identifier data

#### Scenario: Multiple mode blocks duplicate identifiers

- **GIVEN** section S already contains a non-deleted unit with normalized identifier `101`
- **WHEN** a multiple creation request includes an equivalent identifier for S
- **THEN** the duplicate row is rejected
- **AND** no duplicate non-deleted unit is created in S

### Requirement: Manual wizard unit edit is descriptive only

The system SHALL allow authorized step 3 users to edit only descriptive unit fields through the unit edit dialog: `area_m2`, optional `display_name`, `unit_type`, and `identifier`. The update MUST delegate to `Units::Update`.

The edit operation MUST NOT accept property, organization, section placement, status, lifecycle, or code changes. Identifier updates SHALL preserve the existing unit-code behavior defined by the unit contract.

#### Scenario: Edit updates allowed descriptive fields

- **GIVEN** an authorized user edits unit U in draft property P
- **WHEN** they submit valid `area_m2`, `display_name`, `unit_type`, and `identifier`
- **THEN** `Units::Update` persists those descriptive changes
- **AND** U remains in its original property and section context

#### Scenario: Edit rejects placement change

- **GIVEN** unit U belongs to section A
- **WHEN** the edit request submits section B or another placement value
- **THEN** the placement change is ignored or rejected
- **AND** U remains assigned to section A

#### Scenario: Edit preserves derived code

- **GIVEN** unit U has an existing derived code
- **WHEN** the user changes U's identifier through the edit dialog
- **THEN** the identifier and normalized identifier are validated according to the unit contract
- **AND** U's existing code is not automatically changed

### Requirement: Manual wizard unit deletion soft-deletes units

The system SHALL delete units from step 3 manual management through an explicit soft-delete operation. The operation MUST require authorization, tenant/property scoping, and confirmation in the UI before the request is sent.

Soft-deleted units SHALL be omitted from the step 3 preview and SHALL release their identifier context according to the existing soft-delete uniqueness contract.

#### Scenario: Confirmed delete soft-deletes unit

- **GIVEN** an authorized user confirms deletion of unit U in draft property P
- **WHEN** the delete request is processed
- **THEN** U is soft-deleted through the supported unit lifecycle operation
- **AND** U no longer appears in the step 3 preview

#### Scenario: Delete without confirmation sends no request

- **GIVEN** the delete confirmation dialog for unit U is open
- **WHEN** the user cancels or closes the dialog
- **THEN** no delete request is sent
- **AND** U remains non-deleted

#### Scenario: Soft-deleted unit releases identifier context

- **GIVEN** unit U in section S is soft-deleted
- **WHEN** an authorized user creates another unit in S with U's former identifier
- **THEN** creation may succeed if all other unit rules pass

#### Scenario: Unauthorized delete is denied

- **GIVEN** a user lacks unit management capability for property P
- **WHEN** they attempt to delete unit U from P
- **THEN** authorization is denied
- **AND** U remains non-deleted
