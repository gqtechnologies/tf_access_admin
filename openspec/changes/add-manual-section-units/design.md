## Context

The setup wizard already separates structure definition in step 2 from unit creation in step 3. Step 2 uses `ManualSectionForm.vue`, `ManualSectionTreeRow.vue`, and the shared `StructurePreviewPanel.vue` / `StructurePreviewTreeNode.vue` pattern for live structure feedback. Step 3 already supports unit creation modes and automatic previews through `Properties::Setup::GenerateUnitsPreview`, `Properties::Setup::ApplyAutomaticUnits`, and `Units::Create`.

This change adds manual unit management to step 3 without changing the two-level section model. Unit actions must remain tenant-scoped to the draft property and must continue delegating to `Units::*` services and `UnitPolicy`.

Affected models: `ResidentialProperty`, `PropertySection`, `Unit`.
Affected services: `Properties::Setup::*`, `Units::Create`, `Units::Update`, `Units::SoftDelete`.
Affected tables: `residential_properties`, `property_sections`, `units`.
Integration points: `Admin::PropertySetup::WizardController`, `Admin::PropertySetup::WizardSerializer`, property setup Vue components, shared preview components, unit schemas/forms, routes, i18n.

## Goals / Non-Goals

**Goals:**

- Show a section-oriented manual unit management view in step 3 using the same preview model as step 2.
- Let users add one unit or many units from an eligible section.
- Let users edit a unit's descriptive fields in a dialog: `area_m2`, optional `display_name`, `unit_type`, and `identifier`.
- Let users delete a unit only after confirmation, using soft delete.
- Keep all unit mutations scoped to the current draft property and organization.
- Internationalize all new labels, empty states, validation messages, dialog copy, and action text in `es`, `en`, and `pt`.

**Non-Goals:**

- Moving units between sections from the edit dialog.
- Hard-deleting units.
- Changing ownership, occupancy, visit, import, or property confirmation behavior.
- Replacing the existing automatic generation path for quick structures.
- Adding a new UI library or a new domain abstraction for validation already covered by `Unit`.

## Decisions

### Reuse the shared structure preview for manual unit management

The step 3 manual section view will reuse the structure preview data shape and render units beneath each section. In unit-management mode, section rows expose only "add unit"; section edit/add-child/delete actions remain step 2 concerns.

Alternative considered: create a separate unit tree component. This was rejected because it would duplicate the preview hierarchy and increase the risk of step 2 and step 3 rendering the same structure differently.

### Add a unit-management mode to step 3 instead of changing step 2

Manual unit creation belongs in step 3. Step 2 remains responsible for defining sections only, and its preview continues to render sections without unit actions.

Alternative considered: adding units in step 2 while building sections. This was rejected because it blurs the wizard's step responsibilities and conflicts with the existing five-step contract.

### Resolve section placement on the server

When a user adds units from a section row, the client sends the selected section ID and unit payload. The controller resolves the section through the current draft property and organization before calling `Units::Create`. Invalid, foreign, deleted, or non-eligible sections are rejected by the same rules used by the `Unit` contract.

Alternative considered: trusting the preview's section data in the client. This was rejected because tenant isolation and section eligibility must be enforced server-side.

### Keep edit descriptive and placement-safe

The edit dialog updates only `area_m2`, `display_name`, `unit_type`, and `identifier` through `Units::Update`. It does not accept `property_section_id`, property, organization, lifecycle, or code fields. Identifier updates may re-run normalization and uniqueness validation, but code remains unchanged per the existing unit contract.

Alternative considered: allow changing the section from the edit dialog. This was rejected because placement changes already belong to `Units::MoveToSection` and have distinct uniqueness and eligibility semantics.

### Delete through explicit soft-delete service

Manual unit deletion will call `Units::SoftDelete` and never `destroy` directly. The confirmation dialog must appear before the request is sent, and successful deletion removes the unit from the rendered preview because non-deleted units are the visible set.

Alternative considered: use `Units::Archive`. This was rejected because the requested behavior is deletion that releases the identifier context, while archive is a non-destructive business retirement that preserves uniqueness.

### Use existing form conventions

New unit dialogs will define schemas under `app/javascript/lib/schemas/`, use Zod with VeeValidate, display translated errors through `FieldError` and `useTranslateErrors`, and merge server errors with `useServerFormErrors`.

Alternative considered: simple local form state. This was rejected because project form conventions require Zod and VeeValidate for every form.

## Risks / Trade-offs

- [Risk] Multiple creation could partially persist if one unit fails. -> Mitigation: use a service/controller flow that validates the batch before persistence or returns indexed errors without silently advancing the wizard.
- [Risk] Existing automatic generation and new manual multiple creation may diverge. -> Mitigation: keep automatic generation unchanged and define manual multiple allocation separately with explicit preview/confirmation behavior.
- [Risk] Unit deletion could affect later ownership/occupancy work. -> Mitigation: soft delete only, preserve audit/history, and avoid touching ownership/occupancy flows in this change.
- [Risk] Client-side preview could show stale units after mutation. -> Mitigation: reload wizard props or update the preview from the persisted response after every successful create, edit, or delete.
- [Risk] New UI text could miss one locale. -> Mitigation: add keys for `es`, `en`, and `pt` with the same namespace as the setup wizard.
