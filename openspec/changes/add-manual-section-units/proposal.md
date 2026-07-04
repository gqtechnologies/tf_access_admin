## Why

The current setup flow lets users define sections manually, but unit creation is separated from the section-level structure view. Users need a manual way to add, edit, and remove units directly from each eligible section while preserving the same tree preview mental model used in the wizard.

## What Changes

- Add section-level unit management in the unit step using the same shared structure preview pattern used by step 2.
- Replace section actions in this unit-management view with only an "add unit" action for eligible section rows.
- Reuse the existing unit creation choices for individual and multiple creation when "add unit" is triggered from a section.
- Add per-unit dropdown actions for edit and delete.
- Add a unit edit dialog for `area_m2`, optional `display_name`, `unit_type`, and `identifier`.
- Require confirmation before deleting a unit and perform deletion as a soft delete.
- Keep tenant isolation, section eligibility, unit uniqueness, lifecycle, and authorization enforced through existing domain services and policies.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `property-setup-wizard`: Step 3 gains manual section-level unit creation and management while reusing the shared preview model.
- `manual-structure-builder`: The shared preview receives a unit-management mode where section rows expose only unit creation and unit rows expose edit/delete actions.
- `unit`: Unit lifecycle requirements clarify manual wizard edit/delete behavior, including descriptive edit fields and soft delete through an explicit lifecycle operation.

## Impact

### Bounded context

- Affected domains: Residential Properties, Property Sections, Units, Property Setup Wizard.
- Integration points: Rails wizard controllers/services, Unit domain services, PropertySection eligibility rules, Inertia props, Vue step 3 pages/components, shared structure preview, Zod/VeeValidate unit forms, i18n keys.

### Affected models, services, and tables

- Models: `ResidentialProperty`, `PropertySection`, `Unit`.
- Services: `Properties::Setup::*`, `Units::Create`, `Units::Update`, a supported unit soft-delete lifecycle service if present or added for this change.
- Tables: `residential_properties`, `property_sections`, `units`.

### Tenant isolation and authorization

- All unit reads and writes remain scoped to the draft property and current organization.
- Manual unit create/edit/delete actions require the same property-scoped unit management capability used by existing unit mutations.
- Section IDs submitted from the client must be resolved through the current draft property; foreign or ineligible sections are rejected without exposing cross-tenant data.

### Dependencies

- Depends on the existing property setup wizard, manual structure builder, property-section, and unit contracts.
- No dependency on another in-progress OpenSpec change is assumed.

### Non-goals

- No bulk Excel import redesign.
- No changes to ownership, occupancy, visit, or resident flows.
- No hard-delete behavior for units.
- No placement move from the edit dialog; changing a unit's section remains a separate supported lifecycle operation.
- No exact visual replication beyond the observable behavior and existing design system conventions.
