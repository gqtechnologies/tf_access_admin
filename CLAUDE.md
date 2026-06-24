# tf_access_admin

Multi-tenant residential property & visit management platform. Ruby on Rails backend rendering Vue 3 pages through Inertia.

## Stack

- Ruby 3.3.6, Rails ~> 8.1
- Inertia (`inertia_rails`) + Vue 3 (`@inertiajs/vue3`), Composition API + `<script setup>` + TypeScript
- Vite (`vite-plugin-ruby`) for assets, source dir `app/javascript`
- Tailwind CSS v4, reka-ui / shadcn-vue components
- Sidekiq for background jobs
- `acts_as_tenant` for multitenancy, Pundit for authorization, Rolify for roles, `audited` for audit trails
- Minitest for tests, RuboCop (rails-omakase) for Ruby style, Brakeman + bundler-audit for security

## Layout

- `app/models/` — domain models; concerns in `app/models/concerns/`
- `app/policies/` — Pundit policies (capability-based; see Authorization below)
- `app/services/` — service objects / use cases (e.g. `Authorization::*`, `People::*`, `OperationalRoles::*`)
- `app/serializers/` — props/contracts sent to the frontend
- `app/controllers/` — thin controllers, render Inertia pages
- `app/javascript/pages/` — Inertia page components (Vue)
- `app/javascript/components/`, `layouts/`, `lib/` — shared frontend code
- `test/` — Minitest mirrors `app/` structure; shared helpers in `test/support/`
- `openspec/` — OpenSpec change proposals, specs, and task lists

## Core domains

Organizations · Residential Properties · Property Sections · Units · Persons · Unit Ownerships · Unit Occupancies · Staff Assignments · Visits (future) · Bulk Imports · Authentication & Authorization · Auditing

## Conventions

### Multitenancy (strict)
- Every tenant-scoped model belongs to `organization`; never query tenant records globally.
- Scope through `Current.organization` / `current_organization` or an explicit parent resource — not raw `Model.find(params[:id])`.
- Policies enforce tenant isolation. No cross-organization access, even for admins.
- Tenant-scoped uniqueness indexes must include `organization_id`.

### Rails
- Prefer Rails conventions before custom abstractions; keep controllers thin.
- Business logic in service objects / use cases, not controllers.
- Strong params, model validations, and DB constraints where integrity matters.
- Prefer `normalizes` for simple input normalization.
- Prefer soft delete / validity periods (`status`, `starts_at`, `ends_at`) over hard deletes for historical data.
- Add indexes for FKs and frequent lookups. Maintain auditability (`audited`) for ownership, occupancy, and staff/role changes.
- Write tests for policies, services, and critical model rules. When adding a CRUD, mirror an existing one (e.g. `ResidentialProperty`).

### Authorization (capability-based)
- `Authorization::Resolver` is the single source of effective capabilities; it always starts from `User`, never directly from `Person`.
- Capabilities live in `Authorization::Capabilities`; role→capability maps and staff-type normalization in `Authorization::StaffRoleMapper`.
- Organizational roles (`tenant_admin`, `content_manager`) are org-wide; property roles (`property_admin`, `concierge`, `cleaning_staff`, `internal_staff`) are always scoped per `residential_property_id` and derived from active `StaffAssignment`.
- Owner/resident capabilities derive from active `UnitOwnership` / `UnitOccupancy`.
- Policies call `allowed?(capability)` / `can?` via `ApplicationPolicy`, not hard-coded role strings or only `admin?`.

### Vue / Inertia
- Composition API with `<script setup>` and typed props.
- Props from Rails must be explicit and minimal; keep authorization/scoping in Rails.
- Reuse existing components, layouts, shared props, pagination/filter/sort patterns before creating new ones.
- Do not duplicate business rules in Vue; do not introduce new UI libraries unless requested.

### i18n (required for ALL user-facing text)
- Every user-facing string MUST be internationalized. Never hardcode literal text in views, components, serializers, flash messages, validations, or emails.
- Supported locales live in `config/locales/` (`es`, `en`, `pt`; plus `devise.*`). Add a key to every locale file when introducing a new string.
- Rails: use `I18n.t` / `t(".key")`; rely on locale YAML and Rails conventions for model/attribute names and error messages.
- Vue: use `vue-i18n` via `const { t } = useI18n()` and `t('some.key')` / `{{ t('some.key') }}`. Do not inline literal strings in templates.
- Frontend translations are sourced from Rails and passed to `vue-i18n` through Inertia shared props (`app.locale`, `app.translations`) in `app/javascript/entrypoints/inertia.ts`. Add frontend-facing keys to the Rails locale files so they reach both sides; keep `fallbackLocale: 'en'` populated.
- Use nested, namespaced keys mirroring the feature (e.g. `admin.sidebar.operational_roles`). Use interpolation/pluralization instead of string concatenation.

## Workflow

- Keep changes minimal and scoped.
- For non-trivial changes or when the user references an OpenSpec change, follow the OpenSpec workflow.
- Use skills lazily and only when they directly apply to the current task.
- Do not produce implementation summaries or change logs unless explicitly requested.

## Context & Token Efficiency

Prefer minimal, targeted context.

* Do not read broad directories or full files unless required.
* Prefer targeted search/grep before opening complete files.
* Do not reread the same section unless the previous read was insufficient or contradictory.
* Before making non-trivial edits, identify the smallest set of files needed.
* Avoid long terminal output. When commands fail, focus on the first relevant error.
* Run focused tests first. Do not run the full suite unless explicitly requested or required by the task.
* Do not produce implementation summaries, change logs, or long explanations unless explicitly requested.
* If more than 6 additional files seem necessary, pause and explain why before loading more context.
* Prefer `rg`/targeted search before opening complete files.
* When a match is found, read only the minimum surrounding range needed.

## Skills

Use skills lazily and only when they directly apply to the current task.
Available skills:
- `rails-expert`
- `vue`
Skill loading rules:

- Use `rails-expert` when modifying:
  - `app/models/**`
  - `app/controllers/**`
  - `app/policies/**`
  - `app/services/**`
  - `app/serializers/**`
  - `app/jobs/**`
  - `db/migrate/**`
  - `config/routes.rb`
  - Rails tests under `test/**`

- Use `vue` when modifying:
  - `app/javascript/pages/**`
  - `app/javascript/components/**`
  - `app/javascript/layouts/**`
  - `app/javascript/lib/**`
  - Vue components
  - TypeScript frontend code
  - Inertia props consumed by Vue pages
  - frontend i18n usage
  
- If a task touches both Rails props/serializers/controllers and Vue pages/components, use both `rails-expert` and `vue`.
- Do not load every available skill by default.
- If the task is small and the relevant convention is already clear from nearby code, prefer following existing patterns without loading extra skills.
- If a skill is loaded, use only the relevant section. Do not restate or summarize the skill in the final response.

## OpenSpec Workflow

Follow OpenSpec only for non-trivial changes or when the user references an OpenSpec change.

For OpenSpec implementation tasks:

* `tasks.md` defines scope.
* `specs/**/spec.md` defines business rules and acceptance scenarios.
* `design.md` defines technical strategy and implementation decisions.
* `proposal.md` defines motivation and should only be read when the scope or intent is unclear.

Reading rules:

* Read only the current numbered task section from `tasks.md`.
* Do not read full `tasks.md` unless dependencies are unclear.
* Read `specs/**/spec.md` with targeted search for Requirements/Scenarios directly related to the current task.
* Do not read full specs by default.
* Read `design.md` only for technical decisions related to the current task.
* Do not read `proposal.md` unless the goal, scope, or motivation is ambiguous.
* Before editing, produce a brief plan with:

  * current task items detected
  * business rules from related spec scenarios
  * technical decisions from design, if needed
  * maximum 6 files expected to be reviewed or modified
* Implement only the requested task section.
* Mark `- [ ]` → `- [x]` only for completed tasks in the requested section.
* If a requested item depends on incomplete prior work, report it instead of implementing out-of-scope work.

## graphify

This project has a knowledge graph at `graphify-out/` with god nodes, community structure, and cross-file relationships.

Use graphify selectively.

* Prefer grep/search/direct file lookup for simple file location or known symbols.
* Use graphify when relationships are unclear, impact spans multiple layers, or the task asks for architectural understanding.
* Do not run broad graphify queries by default.
* Prefer focused commands:

  * `graphify path "<A>" "<B>"` for relationships.
  * `graphify explain "<concept>"` for a focused concept.
  * `graphify query "<specific question>"` only when the question is narrow.
* Avoid graphify queries that return large subgraphs unless broad architecture review is explicitly needed.
* If `graphify-out/wiki/index.md` exists, use it for broad navigation before reading `GRAPH_REPORT.md`.
* Read `graphify-out/GRAPH_REPORT.md` only for broad architecture review or when query/path/explain are insufficient.
* After modifying code, run `graphify update app` unless the user says not to.
* If `graphify update app` fails, report the error briefly. Do not debug graphify issues unless they were caused by the current changes.

## Validation

Use the cheapest validation that gives confidence.

* For Rails changes, prefer targeted Minitest files or line-based tests first.
* For Vue/TypeScript changes, prefer `npm run check` only when frontend types may be affected.
* For style/security, run RuboCop, Brakeman, bundler-audit, or full `bin/ci` only when explicitly requested or when the task requires it.
* Avoid repeated `git diff` calls. Use one final diff review before finishing, or after a major change when necessary.

## Final Response

Unless the user asks for a detailed summary, respond only with:

* Files modified.
* Tasks completed.
* Tests/validations executed.
* `graphify update app` result, when applicable.
* Pending risks or blockers.

Do not include long implementation summaries.
