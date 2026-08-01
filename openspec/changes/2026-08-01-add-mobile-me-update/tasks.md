## 1. Migration

- [x] 1.1 Migration `20260801000001_add_profile_fields_to_users.rb` (`phone_country_code`, `phone_number`, `date_of_birth`, `gender`). `db/schema.rb` hand-updated to match (Docker unavailable in this environment to run `db:migrate` — **run it for real before merging**, and diff-check the generated schema matches this hand edit).

## 2. Model

- [x] 2.1 `app/models/user.rb`: `validates :gender, inclusion: { in: %w[female male other prefer_not_to_say] }, allow_nil: true`. Schema annotation comment updated.

## 3. Routes + controller

- [x] 3.1 `config/routes.rb`: added `patch :me, to: "me#update"`.
- [x] 3.2 `app/controllers/api/v1/mobile/me_controller.rb`: `show_payload` shared by `#show`/`#update`, includes `phone`/`dateOfBirth`/`gender`. `#update` added per design.md decisions 3/4 (explicit-null-clears-phone handling).

## 4. i18n

- [ ] 4.1 Skipped: no custom `activerecord.errors.models.user.attributes.gender` message added — falls back to Rails' default `inclusion` message + humanized attribute name. Acceptable since the mobile client's fixed `GENDER_OPTIONS` means a real user can never trigger this path; only a malformed/forged request would. Revisit if that stops being true.

## 5. Tests

- [x] 5.1 `test/controllers/api/v1/mobile/me_controller_test.rb` extended: successful update, unset-fields-render-null, explicit-null-phone-clears, invalid gender 422, unauthenticated update 401. Avatar multipart upload test **not added** (would need a fixture file + more setup than justified here — `has_one_attached` is exercised nowhere else in this test file either; flagged as a gap, not silently skipped).

## 6. Validation

- [ ] 6.1 Run migration + `bin/rails test test/controllers/api/v1/mobile/me_controller_test.rb`. **Not done in this environment** — Docker daemon not running. Ruby syntax-checked (`ruby -c`) on every changed/new file as a partial substitute.
