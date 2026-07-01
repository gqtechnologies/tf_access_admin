## 1. DomainCodes foundation

- [ ] 1.1 Add `DomainCodes::Slug` with transliteration, hyphen rules, segment length cap, and tests
- [ ] 1.2 Add `DomainCodes::TypeAbbrev` mapping for `PropertyTypes::ALL` and section types with tests
- [ ] 1.3 Add shared `DomainCodes::CollisionResolver` (numeric `-2`, `-3` suffix within a scope proc) with tests

## 2. Property code derivation

- [ ] 2.1 Implement `DomainCodes::DerivePropertyCode` (type abbrev + name slug + org-scoped collision)
- [ ] 2.2 Wire into `Properties::Create` and `Properties::InitializeDraft` — always derive, never accept client value
- [ ] 2.3 Remove `:code` from `residential_properties_controller` strong params (create and update)
- [ ] 2.4 Remove `code` input from `residential_property/Form.vue`
- [ ] 2.5 Add service tests covering derivation and collision suffix

## 3. Section code derivation

- [ ] 3.1 Implement `DomainCodes::DeriveSectionCode` (root vs child patterns, in-memory parent/property code fallback)
- [ ] 3.2 Wire into `PropertySections::Create` — always derive, never accept client value
- [ ] 3.3 Update `PropertySections::CreateBatch` to derive per section (remove single-code-only restriction if present)
- [ ] 3.4 Remove `:code` from `wizard_controller` strong params: `step_params`, `batch_section_params`, `section_update_params`, and section create params
- [ ] 3.5 Remove `:code` from `property_sections_controller` strong params (create and update)
- [ ] 3.6 Remove `code` inputs (create + edit) from `ManualSectionForm.vue`
- [ ] 3.7 Remove `code` input from `property_section/StructureForm.vue`
- [ ] 3.8 Add service tests for root, child, batch, and collision

## 4. Unit normalized_identifier and code

- [ ] 4.1 Migration: `add_column :units, :code, :string` + separate partial unique indexes for sectioned and root-level unit code contexts
- [ ] 4.2 Align `Units::NormalizeIdentifier` to derive `normalized_identifier` via `DomainCodes::Slug`; update existing tests
- [ ] 4.3 Add `validates_alphanumeric_hyphen_code :code, allow_blank: true` and code uniqueness validation on `Unit`
- [ ] 4.4 Implement `DomainCodes::DeriveUnitCode` using persisted `normalized_identifier` + section/property context
- [ ] 4.5 Wire into `Units::Create` — normalize first, then derive code; strip client-submitted `code`
- [ ] 4.6 Expose `code` in unit serializers (read-only); do not add to strong params or forms
- [ ] 4.7 Rake task: delete all records referencing each `residential_property_id` (visits, ownerships, occupancies, units, sections, staff, incidents, etc.) then delete properties — dev/test only
- [ ] 4.8 Add service tests: `Área 4` → `normalized_identifier: area-4` → code segment; `Area 4`/`Área 4` uniqueness; move keeps code

## 5. Frontend

- [ ] 5.1 Update `Step4Summary.vue`: remove `code` table column; units table shows only `{{ unit.identifier }}`

## 6. Verification

- [ ] 6.1 Run targeted Minitest: `DomainCodes`, `Units::NormalizeIdentifier`, property/section/unit create services
- [ ] 6.2 Run `npm run check` after Vue form changes
- [ ] 6.3 Run `graphify update app` after code changes
