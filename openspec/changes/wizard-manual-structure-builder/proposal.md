## Why

Wizard step 2 only offers a usable "quick" structure flow (format-driven) and a placeholder "manual" form that can only append sections, posts to a route that does not exist, and cannot edit or delete. Properties whose layout does not match a catalog format (or that need a bespoke arrangement) have no real way to build their section tree in the setup flow. We need a first-class manual structure builder that lets users compose a free-form hierarchy within the existing two-level rules, and that feeds the same automatic unit-generation flow currently reserved for quick mode.

## What Changes

- Add a real **manual structure builder** in wizard step 2: create, rename, and delete sections, choose each section's type and parent, and see the tree update live in the shared structure preview panel.
- Enforce the existing hierarchy rules in the builder UX (max two levels: root section + child section; a section with children cannot hold units; units attach only to leaf sections — a childless root or a child section).
- Add a **delete-section** action to the wizard (route + controller + service call), with guards that prevent removing sections that already hold units or children unless explicitly cascaded per existing model rules.
- Fix the manual form's submit target to the real wizard section endpoint and align payload/validation.
- Generalize **automatic unit generation** so it works for manually-built structures, not just quick mode: derive the leaf sections (sections that accept units) from the actual persisted tree instead of assuming `floor` typing, and keep the established identifier-format rules (`floor_sequential` / `block_sequential` / `sequential`, `units_per_leaf`).
- Allow step 3's automatic generation mode when `structure_mode === 'manual'` and the tree has at least one unit-eligible leaf section, reusing the step-3 gate added previously for quick mode.
- Add i18n keys (`es`, `en`, `pt`) for all new builder labels, actions, confirmations, and validation messages.

## Capabilities

### New Capabilities
- `manual-structure-builder`: Interactive creation, editing, and deletion of a property's section hierarchy inside the setup wizard, constrained to the two-level model and unit-placement rules, with live preview.

### Modified Capabilities
- `property-setup-wizard`: Step 2 manual mode becomes a full builder (create/edit/delete + live preview); step 3 automatic unit generation is no longer restricted to quick structures and derives leaf sections from the actual tree.

## Impact

- **Bounded context:** Residential Properties / Property Sections / Units, within the Property Setup Wizard. Integration points: `Properties::Setup::*` services, `PropertySections::Create` (+ a destroy/update path), `PropertySection` hierarchy concern, and the step-2/step-3 Vue components.
- **Models / tables:** `property_sections` (no schema change expected — reuses existing `parent_id`, `section_type`, `position`, soft-delete). `units` unaffected structurally.
- **Services:** `Properties::Setup::GenerateUnitsPreview` (generalize leaf detection beyond `floor`), `Properties::Setup::ApplyAutomaticUnits` (place units into derived leaf sections), `Properties::Setup::ValidateStep` (step-2 manual validity, step-3 leaf-section gate for manual), plus a section-destroy use case (`PropertySections::Destroy` or reuse of existing soft-delete).
- **Controllers / routes:** `Admin::PropertySetup::WizardController` — add `destroy_section` (and confirm `create_section` payload/route), wire into `config/routes.rb`.
- **Frontend:** `ManualSectionForm.vue` (rework to builder), `Step2Structure.vue`, `Step3Units.vue`, shared `StructurePreviewPanel.vue` usage; section-structure Zod schema.
- **Tenant isolation & authorization:** All section reads/writes stay scoped to the property and organization; section create/delete authorized through the property setup capability (`authorize_setup_property!`) — no cross-organization access, consistent with existing wizard endpoints.
- **Dependencies:** Builds on the archived `improve-property-structure-wizard-formats` change (step-3 gate, `units_in`, identifier formats, preview panel).

## Non-goals

- No change to the two-level hierarchy limit itself (no arbitrary-depth trees).
- No new section types or changes to `SectionTypes` eligibility rules.
- No bulk/CSV structure import (that remains the separate bulk-import flow).
- No redesign of quick mode or the format catalog.
- No changes to unit ownership/occupancy or post-setup property editing screens.
