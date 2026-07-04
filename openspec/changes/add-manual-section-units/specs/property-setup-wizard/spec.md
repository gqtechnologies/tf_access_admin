## ADDED Requirements

### Requirement: Step 3 supports manual section-level unit management

Step 3 SHALL provide a manual section-level unit management mode for draft properties. The mode SHALL show the same persisted structure preview model used by step 2, with units rendered under their assigned eligible section when present.

The manual section-level mode SHALL be available when the property has sections. In this mode, sections SHALL NOT expose section edit, add-child, or delete actions; each eligible section row SHALL expose only an add-unit action. Unit creation, edit, and deletion SHALL remain scoped to the current draft property and organization and SHALL require the property-scoped unit management capability.

#### Scenario: Manual unit view reuses section preview

- **GIVEN** a draft property has persisted sections from step 2
- **WHEN** the user opens step 3 manual unit management
- **THEN** the step renders the same structure preview shape used by step 2
- **AND** any existing non-deleted units are shown beneath their assigned section

#### Scenario: Section rows expose only add-unit action

- **GIVEN** the user is viewing sections in step 3 manual unit management
- **WHEN** an eligible section row renders
- **THEN** it exposes an add-unit action
- **AND** it does not expose edit-section, add-child-section, or delete-section actions

#### Scenario: Add-unit opens individual and multiple options

- **GIVEN** the user triggers add-unit from an eligible section
- **WHEN** the creation dialog opens
- **THEN** it offers individual and multiple creation modes
- **AND** created units are assigned to that section through the draft property's server-side context

#### Scenario: Ineligible section cannot receive units

- **GIVEN** a section is not eligible to contain units according to the property-section contract
- **WHEN** the user attempts to create a unit for that section
- **THEN** the mutation is rejected
- **AND** no unit is created or silently assigned elsewhere

#### Scenario: Manual unit mutations refresh preview

- **GIVEN** the user creates, edits, or deletes a unit in step 3
- **WHEN** the mutation succeeds
- **THEN** the preview reflects the persisted non-deleted units without losing wizard state

#### Scenario: Cross-organization unit mutation is denied

- **GIVEN** the user is operating in organization O
- **WHEN** a step 3 unit mutation references a property, section, or unit from organization Q
- **THEN** access is denied
- **AND** no foreign data is returned or mutated
