## 1. Shared unit-generation plan

- [ ] 1.1 Extract a pure calculation object (e.g. `Properties::Setup::UnitGenerationPlan`) that, given `property`, resolved `PropertyStructureFormat`, and `unit_generation` params (`unit_type`, `identifier_format`, `units_per_leaf`), returns one row per planned unit: `{ property_section (leaf or nil), identifier, unit_type }`.
- [ ] 1.2 Resolve leaf sections via `StructureFormatResolver.for(property_type:)` / `format.units_in` (generalize beyond the current hardcoded `SectionTypes::FLOOR`).
- [ ] 1.3 Implement `floor_sequential` identifier numbering as `"#{leaf.position * 100 + index + 1}"` (unchanged formula, now shared).
- [ ] 1.4 Implement `block_sequential` identifier numbering as `"B#{leaf.position * 100 + index + 1}"` — same position-based formula as `floor_sequential` with a `B` prefix, starting at `B1`-equivalent (`B101` for position 1). This corrects the current bug where block identifiers ignore leaf position and start at `B2`.
- [ ] 1.5 Implement `sequential` identifier numbering as `"#{index + 1}"`, reset at the start of every leaf section (not continuous across the whole property).
- [ ] 1.6 Preserve the existing flat/unsectioned fallback when the property type has no recommended `PropertyStructureFormat` (mirrors `ApplyQuickStructure`'s existing fallback).
- [ ] 1.7 Unit-test the plan object directly: multiple leaves, single leaf, no leaves (fallback), each `identifier_format` (including block position 1 vs 2 producing `B101...`/`B201...`), and different `unit_type` values.

## 2. Align preview with the plan

- [ ] 2.1 Rewrite `Properties::Setup::GenerateUnitsPreview#build_rows` to use the shared plan object instead of its own hardcoded `floor`-only logic.
- [ ] 2.2 Ensure paginated preview rows still include `tower`/`floor` (or equivalent leaf ancestry) and `identifier` for display.
- [ ] 2.3 Rename `quantity_per_floor` to `units_per_leaf` in `GenerateUnitsPreview` (`@params.fetch(:units_per_leaf, 4)`).
- [ ] 2.4 Rename `quantity_per_floor` to `units_per_leaf` in `Admin::PropertySetup::WizardController#units_preview_params` (`params.permit(:unit_type, :identifier_format, :units_per_leaf)`); confirm no other reference to `quantity_per_floor` remains in the backend.
- [ ] 2.5 Update/extend `Properties::Setup::GenerateUnitsPreview` tests to cover block-leaf and sequential-format cases that were previously unsupported, and to confirm `units_per_leaf` is honored (regression test for the previously-ignored param).

## 3. Align client-side preview

- [ ] 3.1 Fix `floorBase`/`unitIdentifiers` in `app/javascript/lib/property_setup/unitsPreview.ts` so `block_sequential` uses `leaf.position` (falling back to the existing name-based digit extraction already used for `floor_sequential`) and starts at `B1`-equivalent per position, matching the backend formula from task 1.4.
- [ ] 3.2 Confirm `sequential` and `floor_sequential` behavior in `unitsPreview.ts` is unchanged (already correct).
- [ ] 3.3 Confirm `Step3Units.vue`'s static `exampleIdentifiers` computed (used before a property/tree exists) matches the corrected formula, or is clearly labeled as an illustrative example rather than an exact preview.

## 4. Fix automatic unit persistence

- [ ] 4.1 Rewrite `Properties::Setup::ApplyAutomaticUnits#call` to iterate the shared plan and call `Units::Create.call(actor:, property:, section_id: leaf&.id, attributes: { identifier:, unit_type: })` per planned row.
- [ ] 4.2 Replace the blanket `return Result.success(@property) if @property.units.any?` guard with a per-row check: skip creation only when a non-deleted unit already exists at the exact planned `(property_section_id, identifier)`; otherwise create it.
- [ ] 4.3 Collect and return per-row failures on the `Result` (do not swallow a mid-loop `Units::Create` failure as a whole-batch success or an opaque generic invalid).
- [ ] 4.4 Confirm derived `code` and `normalized_identifier` still come from `Units::Create` / `Unit` (no duplication of that logic here).

## 5. Propagate failures from the wizard controller

- [ ] 5.1 Update `Admin::PropertySetup::WizardController#apply_units_step!` to return the `Result` from `Properties::Setup::ApplyAutomaticUnits.call`.
- [ ] 5.2 Update `#advance` so that when step 3's side effect fails, the wizard stays on step 3, `current_step` is not advanced, and errors are rendered the same way other step-3 failures are (see `Invalid units block summary progression`).
- [ ] 5.3 Confirm `individual`/`import` mode branches are unaffected by this change.

## 6. Tests

- [ ] 6.1 Service test: automatic generation with a multi-leaf quick structure (e.g. 2 towers x 3 floors) creates `units_per_leaf` units under each leaf, none unsectioned.
- [ ] 6.2 Service test: automatic generation honors configured `unit_type` and `identifier_format` (cover `floor_sequential`, `block_sequential`, `sequential`), asserting the exact identifiers per leaf position (e.g. block 1 → `B101, B102`, block 2 → `B201, B202`).
- [ ] 6.3 Service test: automatic generation uses the correlativo/quantity configured in the form (per leaf, not a flat total).
- [ ] 6.4 Service test: a mid-batch `Units::Create` failure is reported on the `Result` and does not silently report success.
- [ ] 6.5 Service test: re-running automatic generation on a property with a partially-created batch fills in only the missing units per leaf (no duplicates, no silent no-op).
- [ ] 6.6 Request/controller test: step 3 advance in automatic mode with valid config creates the expected units and advances to step 4.
- [ ] 6.7 Request/controller test: step 3 advance in automatic mode with a forced failure keeps the wizard on step 3, shows an error, and does not advance `current_step`.
- [ ] 6.8 Request/controller test: automatic generation remains unavailable/rejected when `structure_mode` is not `quick` (regression guard — must not break existing behavior from `ValidateStep#validate_step_3`).
- [ ] 6.9 Confirm existing `unit` capability tests (uniqueness, normalization, section eligibility) are exercised transparently through `Units::Create` for automatically generated units — no new duplicate assertions of those rules here.
- [ ] 6.10 Frontend test/manual check: `unitsPreview.ts` `block_sequential` output matches the backend formula (`B101, B102...` for position 1, `B201...` for position 2).

## 8. Generalize review-summary counts (BuildPreview)

- [ ] 8.1 In `Properties::Setup::BuildPreview#call`, resolve `format = StructureFormatResolver.for(property_type: @property.property_type)`.
- [ ] 8.2 Replace the hardcoded `towers: sections.where(section_type: SectionTypes::TOWER)` / `floors: sections.where(section_type: SectionTypes::FLOOR)` counts with counts keyed by `format.levels.first[:section_type]` (top level) and `format.units_in` (leaf level) when a format is resolved; expose them as `counts.level_1` / `counts.level_2`, matching the existing convention already used by `GenerateStructurePreview.counts`. When no format is resolved for the property type, both counts are `0`.
- [ ] 8.3 Fix `unit_preview_row` to use `unit.code` instead of `unit.identifier` for the `code:` field.
- [ ] 8.4 Add/extend `Properties::Setup::BuildPreview` tests: a `condominium`/`sector` property shows non-zero, correct `level_1`/`level_2` counts (regression for the current always-zero bug); a `building`/`tower` property's counts are unaffected; `unit_preview_row[:code]` matches `unit.code`, not `unit.identifier`.

## 9. Fix Step3Units.vue defaults and consume generalized counts

- [ ] 9.1 Add `{ immediate: true }` to the `watch(() => props.unitsIn, ...)` in `Step3Units.vue` so `autoForm.identifier_format` initializes correctly on first render/resume for block-based properties, not only on later changes to `unitsIn`.
- [ ] 9.2 Update `towerCount`/`floorCount` (and any template usage) in `Step3Units.vue` to read `preview.counts.level_1` / `preview.counts.level_2` instead of the now-removed `counts.towers` / `counts.floors`.
- [ ] 9.3 Update the step 3 "context" i18n strings (`towers`, `floors` keys) in `es.yml`/`en.yml`/`pt.yml` so block/sector-based properties use the existing generic `structure_count` wording instead of literal "torres"/"pisos" phrasing when `unitsIn !== 'floor'`.
- [ ] 9.4 Check `Step2Structure.vue` and any other consumer of `preview.counts.towers`/`floors` for the same rename, so nothing else silently breaks.

## 10. Validation and closeout

- [ ] 10.1 Run the affected Minitest suites (`properties/setup` services, wizard controller requests, units preview).
- [ ] 10.2 Run RuboCop on changed files.
- [ ] 10.3 Run TypeScript/Vue checks for the touched frontend files (`unitsPreview.ts`, `Step3Units.vue`, `Step2Structure.vue` if touched).
- [ ] 10.4 Run `openspec validate fix-automatic-unit-generation --type change --strict`.
- [ ] 10.5 Confirm proposal, design, spec deltas and tasks stay aligned after implementation.
- [ ] 10.6 Update Graphify (`graphify update app`) after implementing code.
