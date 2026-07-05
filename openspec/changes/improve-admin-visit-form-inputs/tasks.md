## 1. Searchable Select Component

- [ ] 1.1 Inspect existing `components/ui/select`, `components/ui/popover`, command-like patterns, and form field conventions before building the shared component.
- [ ] 1.2 Create a reusable searchable select component with `v-model`, generic options, selected label, placeholder, disabled, loading, empty, clear, and invalid states.
- [ ] 1.3 Add support for a caller-provided async option loader with a default page size of 20, typed search, pagination metadata, debounce, and lazy loading on scroll.
- [ ] 1.4 Ensure selected default values remain visible even when the selected option is not present in the currently loaded page.
- [ ] 1.5 Add keyboard interaction for open, close, navigate, select, clear, and Escape without changing the selected value.
- [ ] 1.6 Add reusable i18n keys for generic loading/empty/search/clear affordances when visible copy is owned by the component.
- [ ] 1.7 Add recoverable endpoint error handling that preserves the current selected value and label.
- [ ] 1.8 Add optional secondary text rendering for duplicate labels when option data includes it.
- [ ] 1.9 Add focused component/type coverage for search loading, debounce, pagination, selection, default selected display, endpoint error handling, clear behavior, disabled/loading states, empty results, and keyboard behavior where the project test harness supports it.

## 2. Visit Option Search Endpoints

- [ ] 2.1 Add or update tenant-scoped property option search for admin visit creation with page size 20 and trimmed, case-insensitive, accent-insensitive name matching.
- [ ] 2.2 Add or update tenant-scoped unit option search for admin visit creation with property scoping, page size 20, pagination, and trimmed, case-insensitive, accent-insensitive unit name matching.
- [ ] 2.3 Add or update eligible host option search for admin visit creation with unit scoping, page size 20, pagination, and trimmed, case-insensitive, accent-insensitive host name matching.
- [ ] 2.4 Ensure option endpoints return enough selected option display data for contextual/restored default values to remain visible.
- [ ] 2.5 Add targeted Rails/controller coverage for tenant scoping, parent scoping, eligibility, pagination, and accent/case-insensitive matching.

## 3. Admin Visit Step 1 Integration

- [ ] 3.1 Replace the native property select in `VisitCreateGeneralStep.vue` with the searchable select backed by the property option endpoint.
- [ ] 3.2 Replace the native unit select with the searchable select backed by the unit option endpoint while preserving disabled/loading behavior until a property is selected.
- [ ] 3.3 Replace the native host select with the searchable select backed by the host option endpoint while preserving disabled/loading behavior until a unit is selected.
- [ ] 3.4 Preserve existing watchers so property changes or clears clear unit/host and load units, and unit changes or clears clear host and load hosts/status preview.
- [ ] 3.5 Preserve contextual visit creation behavior so locked property/unit values remain visible and cannot be changed.
- [ ] 3.6 Ensure no select auto-selects a single available option.
- [ ] 3.7 Ensure field errors, aria invalid state, empty messages, loading messages, and clear behavior continue to render correctly for all three fields.

## 4. Schedule Defaults

- [ ] 4.1 Add helper logic to initialize blank schedule fields when step 3 renders with the browser's current local date in `YYYY-MM-DD` format.
- [ ] 4.2 Add helper logic to initialize blank schedule fields when step 3 renders with the browser's exact current local time in `HH:mm` format without rounding.
- [ ] 4.3 Ensure `end_time` remains empty by default.
- [ ] 4.4 Ensure restored browser session state and user-entered schedule values are not overwritten by the current date/time defaults.
- [ ] 4.5 Ensure summary and submit payload use the default date/start time when the user does not change them.

## 5. Validation And Authorization Safety

- [ ] 5.1 Verify no backend authorization or tenant scoping is moved into the searchable select.
- [ ] 5.2 Add or update frontend tests for property/unit/host search requesting and rendering authorized options only.
- [ ] 5.3 Add or update tests for contextual unit creation preserving locked property/unit selection and visible selected labels.
- [ ] 5.4 Add tests for restored visit form state preserving saved date/start time.
- [ ] 5.5 Add tests for new empty form defaulting date/start time on step 3 render and not defaulting end time.

## 6. Final Validation

- [ ] 6.1 Run targeted frontend type check for changed Vue/TypeScript files.
- [ ] 6.2 Run targeted visit form tests if a frontend test harness exists for the admin visit form.
- [ ] 6.3 Run targeted Rails controller tests for changed visit form option endpoints.
- [ ] 6.4 Run `openspec validate improve-admin-visit-form-inputs --strict`.
- [ ] 6.5 Run `graphify update app` after implementation changes.
