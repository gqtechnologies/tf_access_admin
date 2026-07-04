## 1. Backend Unit Mutations

- [ ] 1.1 Inspect existing `Admin::PropertySetup::WizardController`, `Admin::ResidentialProperties::UnitsController`, `Units::Create`, `Units::Update`, and `Units::SoftDelete` patterns to mirror routing, authorization, and result handling.
- [ ] 1.2 Add wizard-scoped routes/actions for manual unit create, multiple create, update, and soft delete under the current draft property.
- [ ] 1.3 Resolve submitted `property_section_id` through the current draft property and organization before invoking unit services, while allowing blank section IDs for property-level units.
- [ ] 1.4 Implement manual multiple unit creation with the same generator semantics and limits as manual multiple sections: `cantidad`, optional `prefijo`, `formato`, and a live preview-matching identifier list.
- [ ] 1.5 Persist manual multiple unit creation inside an all-or-nothing transaction and return a descriptive batch alert if any planned unit fails.
- [ ] 1.6 Delegate individual and multiple manual unit creation to `Units::Create` without silently creating duplicates.
- [ ] 1.7 Delegate unit edits to `Units::Update` while permitting only `area_m2`, `display_name`, `unit_type`, and `identifier`; regenerate server-derived `code` when `identifier` changes and reject the identifier update if the regenerated code collides.
- [ ] 1.8 Delegate unit deletion to `Units::SoftDelete`, show the generic related-record warning before request submission, do not block on related records, and ensure deleted units are excluded from subsequent wizard preview props.
- [ ] 1.9 Require `manage_units` permission for wizard draft unit mutations.

## 2. Wizard Props and Preview Data

- [ ] 2.1 Extend property setup serialization/preview data to include non-deleted units grouped under their assigned sections and property-level non-sectioned units for step 3.
- [ ] 2.2 Expose persisted unit IDs and enough unit fields for preview rows and edit dialogs without leaking organization, property, lifecycle, or code mutation fields.
- [ ] 2.3 Ensure manual unit mutations reload or refresh wizard props so the preview reflects persisted create, edit, and soft-delete results.
- [ ] 2.4 Preserve existing automatic generation preview behavior for quick structures.
- [ ] 2.5 Select automatic mode by default on first-time quick setup, and manual mode by default when editing/resuming persisted units.

## 3. Frontend Forms and Interactions

- [ ] 3.1 Add Zod schemas under `app/javascript/lib/schemas/` for manual individual unit, manual multiple unit, and unit edit dialogs.
- [ ] 3.2 Build the add-unit dialog with individual and multiple modes mirroring manual section creation controls, excluding `display_name` from multiple mode, wired through VeeValidate and server error merging.
- [ ] 3.3 Build the unit edit dialog for `area_m2`, optional `display_name`, `unit_type`, and `identifier`.
- [ ] 3.4 Add unit delete confirmation using the existing confirm dialog pattern, include the special related-record warning, and send no request until confirmed.
- [ ] 3.5 Update `Step3Units.vue` to add a new `manual` units mode available for sectioned and non-sectioned properties.
- [ ] 3.6 Show descriptive alert feedback when manual multiple creation rolls back.

## 4. Shared Preview UI

- [ ] 4.1 Reuse/adapt the `ManualSectionForm` and `ManualSectionTreeRow` visual pattern for step 3 unit-management mode.
- [ ] 4.2 In unit-management mode, render section rows with only the add-unit action for eligible unit containers.
- [ ] 4.3 Render unit rows under sections with a dropdown containing exactly edit and delete actions.
- [ ] 4.4 Keep step 2 manual builder behavior unchanged, including section-only preview and section action dropdowns.
- [ ] 4.5 Add empty/zero-unit states for sections without units in step 3.
- [ ] 4.6 Render property-level units and property-level add-unit action for units without a section at the end of the preview component.

## 5. Internationalization

- [ ] 5.1 Add `es`, `en`, and `pt` translations for manual unit mode labels, dialogs, validation messages, dropdown actions, confirmations, empty states, and errors.
- [ ] 5.2 Ensure all new Rails flash/errors and Vue text use i18n keys.

## 6. Tests and Validation

- [ ] 6.1 Add focused controller/service tests for wizard-scoped manual unit create, all-or-nothing multiple create, edit, and soft delete.
- [ ] 6.2 Add tests for tenant isolation, missing section/property-level units, foreign section/unit IDs, ineligible sections, duplicate identifiers, code regeneration on identifier edit, code-collision rejection, `manage_units` authorization, and soft-delete uniqueness release.
- [ ] 6.3 Add frontend type/schema validation coverage or run the focused frontend type check for touched Vue/TypeScript code.
- [ ] 6.4 Run targeted Rails tests for unit services and property setup wizard behavior.
- [ ] 6.5 Run `openspec validate add-manual-section-units --strict`.
- [ ] 6.6 Run `graphify update app` after implementation changes.
