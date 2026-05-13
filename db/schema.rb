# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_13_130005) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "access_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.inet "ip_address"
    t.jsonb "metadata", default: {}, null: false
    t.text "notes"
    t.datetime "occurred_at", null: false
    t.uuid "organization_id", null: false
    t.uuid "recorded_by_user_id"
    t.uuid "residential_property_id", null: false
    t.string "result", default: "success", null: false
    t.string "source", default: "web", null: false
    t.uuid "staff_shift_id"
    t.uuid "unit_id"
    t.datetime "updated_at", null: false
    t.text "user_agent"
    t.uuid "vehicle_id"
    t.uuid "visit_id"
    t.uuid "visit_participant_id"
    t.uuid "visitor_profile_id"
    t.index ["metadata"], name: "index_access_events_on_metadata", using: :gin
    t.index ["organization_id", "event_type", "result", "occurred_at"], name: "index_access_events_on_org_type_result_occurred_at"
    t.index ["organization_id", "residential_property_id", "occurred_at"], name: "index_access_events_on_org_property_occurred_at"
    t.index ["organization_id", "unit_id", "occurred_at"], name: "index_access_events_on_org_unit_occurred_at"
    t.index ["organization_id", "visit_id", "occurred_at"], name: "index_access_events_on_org_visit_occurred_at"
    t.index ["organization_id"], name: "index_access_events_on_organization_id"
    t.index ["recorded_by_user_id"], name: "index_access_events_on_recorded_by_user_id"
    t.index ["residential_property_id"], name: "index_access_events_on_residential_property_id"
    t.index ["unit_id"], name: "index_access_events_on_unit_id"
    t.index ["vehicle_id"], name: "index_access_events_on_vehicle_id"
    t.index ["visit_id"], name: "index_access_events_on_visit_id"
    t.index ["visit_participant_id"], name: "index_access_events_on_visit_participant_id"
    t.index ["visitor_profile_id"], name: "index_access_events_on_visitor_profile_id"
  end

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.uuid "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "authorized_residents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "authorized_by_person_id"
    t.uuid "authorized_by_user_id"
    t.boolean "can_authorize_visits", default: false, null: false
    t.boolean "can_reserve_common_areas", default: false, null: false
    t.boolean "can_withdraw_parcels", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "ends_at"
    t.jsonb "metadata", default: {}, null: false
    t.text "notes"
    t.uuid "organization_id", null: false
    t.uuid "person_id", null: false
    t.string "relationship_type", null: false
    t.datetime "starts_at", null: false
    t.string "status", default: "pending", null: false
    t.uuid "unit_id", null: false
    t.datetime "updated_at", null: false
    t.index ["metadata"], name: "index_authorized_residents_on_metadata", using: :gin
    t.index ["organization_id", "authorized_by_person_id"], name: "index_authorized_residents_on_org_authorized_by_person_id"
    t.index ["organization_id", "person_id", "status"], name: "index_authorized_residents_on_org_person_status"
    t.index ["organization_id", "unit_id", "status"], name: "index_authorized_residents_on_org_unit_status"
    t.index ["organization_id"], name: "index_authorized_residents_on_organization_id"
    t.index ["person_id"], name: "index_authorized_residents_on_person_id"
    t.index ["unit_id"], name: "index_authorized_residents_on_unit_id"
  end

  create_table "flipper_features", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "feature_key", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "icons", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_icons_on_name", unique: true
  end

  create_table "jwt_denylist", force: :cascade do |t|
    t.datetime "exp", null: false
    t.string "jti", null: false
    t.index ["jti"], name: "index_jwt_denylist_on_jti", unique: true
  end

  create_table "lease_contracts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "can_authorize_visits", default: true, null: false
    t.boolean "can_reserve_common_areas", default: true, null: false
    t.boolean "can_withdraw_parcels", default: true, null: false
    t.datetime "created_at", null: false
    t.uuid "created_by_id"
    t.date "ends_at"
    t.uuid "lessee_person_id", null: false
    t.uuid "lessor_person_id"
    t.jsonb "metadata", default: {}, null: false
    t.uuid "organization_id", null: false
    t.date "starts_at", null: false
    t.string "status", default: "draft", null: false
    t.uuid "terminated_by_id"
    t.uuid "unit_id", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_lease_contracts_on_created_by_id"
    t.index ["lessee_person_id"], name: "index_lease_contracts_on_lessee_person_id"
    t.index ["lessor_person_id"], name: "index_lease_contracts_on_lessor_person_id"
    t.index ["metadata"], name: "index_lease_contracts_on_metadata", using: :gin
    t.index ["organization_id", "lessee_person_id", "status"], name: "index_lease_contracts_on_org_lessee_person_status"
    t.index ["organization_id", "unit_id", "starts_at", "ends_at"], name: "index_lease_contracts_on_org_unit_date_range"
    t.index ["organization_id", "unit_id"], name: "index_lease_contracts_on_org_unit_unique_when_active", unique: true, where: "((status)::text = 'active'::text)"
    t.index ["organization_id"], name: "index_lease_contracts_on_organization_id"
    t.index ["terminated_by_id"], name: "index_lease_contracts_on_terminated_by_id"
    t.index ["unit_id"], name: "index_lease_contracts_on_unit_id"
  end

  create_table "organization_memberships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.datetime "joined_at"
    t.jsonb "metadata", default: {}, null: false
    t.uuid "organization_id", null: false
    t.uuid "person_id", null: false
    t.datetime "revoked_at"
    t.string "status", default: "invited", null: false
    t.datetime "suspended_at"
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_organization_memberships_on_deleted_at"
    t.index ["metadata"], name: "index_organization_memberships_on_metadata", using: :gin
    t.index ["organization_id", "person_id"], name: "idx_on_organization_id_person_id_cd1ad4bbc4"
    t.index ["organization_id", "person_id"], name: "idx_org_memberships_unique_active_invited", unique: true, where: "(((status)::text = ANY ((ARRAY['invited'::character varying, 'active'::character varying])::text[])) AND (deleted_at IS NULL))"
    t.index ["organization_id"], name: "index_organization_memberships_on_organization_id"
    t.index ["person_id"], name: "index_organization_memberships_on_person_id"
    t.index ["status"], name: "index_organization_memberships_on_status"
  end

  create_table "organizations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "country_code", default: "CL", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "legal_name"
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.string "plan", default: "free", null: false
    t.jsonb "settings", default: {}, null: false
    t.string "status", default: "active", null: false
    t.string "subdomain"
    t.text "tax_identifier_ciphertext"
    t.string "tax_identifier_digest"
    t.string "tax_identifier_type", default: "rut", null: false
    t.datetime "updated_at", null: false
    t.index ["country_code", "tax_identifier_type", "tax_identifier_digest"], name: "idx_organizations_unique_tax_identifier", unique: true, where: "((tax_identifier_digest IS NOT NULL) AND (deleted_at IS NULL))"
    t.index ["deleted_at"], name: "index_organizations_on_deleted_at"
    t.index ["metadata"], name: "index_organizations_on_metadata", using: :gin
    t.index ["plan"], name: "index_organizations_on_plan"
    t.index ["settings"], name: "index_organizations_on_settings", using: :gin
    t.index ["status"], name: "index_organizations_on_status"
    t.index ["subdomain"], name: "index_organizations_on_subdomain", unique: true
  end

  create_table "people", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.date "birthdate"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "display_name", null: false
    t.text "document_number_ciphertext"
    t.string "document_number_digest"
    t.string "document_type"
    t.text "email_ciphertext"
    t.string "first_name"
    t.string "last_name"
    t.jsonb "metadata", default: {}, null: false
    t.uuid "organization_id", null: false
    t.string "person_type", default: "natural", null: false
    t.text "phone_ciphertext"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["deleted_at"], name: "index_people_on_deleted_at"
    t.index ["metadata"], name: "index_people_on_metadata", using: :gin
    t.index ["organization_id", "display_name"], name: "index_people_on_organization_id_and_display_name"
    t.index ["organization_id", "document_type", "document_number_digest"], name: "idx_people_unique_document_per_org_when_present", unique: true, where: "((document_number_digest IS NOT NULL) AND (deleted_at IS NULL))"
    t.index ["organization_id", "status"], name: "index_people_on_organization_id_and_status"
    t.index ["organization_id", "user_id"], name: "idx_people_unique_user_per_org_when_present", unique: true, where: "((user_id IS NOT NULL) AND (deleted_at IS NULL))"
    t.index ["organization_id", "user_id"], name: "index_people_on_organization_id_and_user_id"
    t.index ["organization_id"], name: "index_people_on_organization_id"
    t.index ["user_id"], name: "index_people_on_user_id"
  end

  create_table "people_roles", id: false, force: :cascade do |t|
    t.uuid "person_id", null: false
    t.uuid "role_id", null: false
    t.index ["person_id", "role_id"], name: "index_people_roles_on_person_id_and_role_id"
  end

  create_table "property_sections", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.uuid "organization_id", null: false
    t.uuid "parent_id"
    t.integer "position"
    t.uuid "residential_property_id", null: false
    t.string "section_type", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_property_sections_on_deleted_at"
    t.index ["metadata"], name: "index_property_sections_on_metadata", using: :gin
    t.index ["organization_id", "residential_property_id", "parent_id", "section_type", "code"], name: "idx_property_sections_unique_code_in_context", unique: true, where: "((code IS NOT NULL) AND (deleted_at IS NULL))"
    t.index ["organization_id", "residential_property_id", "parent_id"], name: "idx_property_sections_on_org_property_parent"
    t.index ["organization_id"], name: "index_property_sections_on_organization_id"
    t.index ["parent_id"], name: "index_property_sections_on_parent_id"
    t.index ["residential_property_id"], name: "index_property_sections_on_residential_property_id"
  end

  create_table "property_setting_versions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "change_reason"
    t.uuid "changed_by_id"
    t.datetime "created_at", null: false
    t.uuid "organization_id", null: false
    t.uuid "property_setting_id", null: false
    t.uuid "residential_property_id", null: false
    t.jsonb "snapshot", default: {}, null: false
    t.datetime "updated_at", null: false
    t.integer "version_number", null: false
    t.index ["changed_by_id"], name: "index_property_setting_versions_on_changed_by_id"
    t.index ["organization_id", "property_setting_id"], name: "idx_property_setting_versions_on_org_and_setting"
    t.index ["organization_id", "residential_property_id", "version_number"], name: "idx_property_setting_versions_on_org_property_version"
    t.index ["organization_id"], name: "index_property_setting_versions_on_organization_id"
    t.index ["property_setting_id"], name: "index_property_setting_versions_on_property_setting_id"
    t.index ["residential_property_id"], name: "index_property_setting_versions_on_residential_property_id"
    t.index ["snapshot"], name: "index_property_setting_versions_on_snapshot", using: :gin
  end

  create_table "property_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "active_notification_channels", default: {}, null: false
    t.boolean "allow_recurring_visits", default: false, null: false
    t.boolean "concierge_can_approve_visits", default: false, null: false
    t.datetime "created_at", null: false
    t.integer "max_reservations_per_month"
    t.integer "max_simultaneous_visitors_per_unit", default: 5, null: false
    t.integer "max_visitors_per_visit", default: 5, null: false
    t.jsonb "metadata", default: {}, null: false
    t.uuid "organization_id", null: false
    t.boolean "parcel_requires_signature", default: false, null: false
    t.integer "reservation_max_duration_minutes"
    t.integer "reservation_min_advance_hours", default: 0, null: false
    t.boolean "reservation_requires_approval", default: true, null: false
    t.uuid "residential_property_id", null: false
    t.datetime "updated_at", null: false
    t.boolean "vehicle_plate_required", default: false, null: false
    t.boolean "visit_requires_concierge_validation", default: true, null: false
    t.boolean "visit_requires_resident_approval", default: true, null: false
    t.boolean "visitor_identity_document_required", default: false, null: false
    t.index ["active_notification_channels"], name: "index_property_settings_on_active_notification_channels", using: :gin
    t.index ["metadata"], name: "index_property_settings_on_metadata", using: :gin
    t.index ["organization_id", "residential_property_id"], name: "idx_on_organization_id_residential_property_id_ef39d448db", unique: true
    t.index ["organization_id"], name: "index_property_settings_on_organization_id"
    t.index ["residential_property_id"], name: "index_property_settings_on_residential_property_id"
  end

  create_table "residential_properties", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "address_line"
    t.string "city"
    t.string "code"
    t.string "country", default: "Chile", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.uuid "organization_id", null: false
    t.string "property_type", null: false
    t.string "region"
    t.string "status", default: "active", null: false
    t.string "timezone", default: "America/Santiago", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_residential_properties_on_deleted_at"
    t.index ["metadata"], name: "index_residential_properties_on_metadata", using: :gin
    t.index ["organization_id", "code"], name: "idx_residential_properties_unique_code_per_org", unique: true, where: "((code IS NOT NULL) AND (deleted_at IS NULL))"
    t.index ["organization_id", "property_type"], name: "idx_on_organization_id_property_type_d2e2ee8ca6"
    t.index ["organization_id", "status"], name: "index_residential_properties_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_residential_properties_on_organization_id"
  end

  create_table "roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.uuid "organization_id"
    t.string "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["name"], name: "index_roles_on_name"
    t.index ["organization_id"], name: "index_roles_on_organization_id"
    t.index ["resource_type", "resource_id"], name: "index_roles_on_resource"
  end

  create_table "unit_occupancies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "can_authorize_visits", default: false, null: false
    t.boolean "can_reserve_common_areas", default: false, null: false
    t.boolean "can_withdraw_parcels", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "ends_at"
    t.jsonb "metadata", default: {}, null: false
    t.string "occupancy_type", null: false
    t.uuid "organization_id", null: false
    t.uuid "person_id", null: false
    t.bigint "source_id"
    t.string "source_type"
    t.datetime "starts_at", null: false
    t.string "status", default: "active", null: false
    t.uuid "unit_id", null: false
    t.datetime "updated_at", null: false
    t.index ["metadata"], name: "index_unit_occupancies_on_metadata", using: :gin
    t.index ["organization_id", "person_id", "status"], name: "index_unit_occupancies_on_org_person_status"
    t.index ["organization_id", "source_type", "source_id"], name: "index_unit_occupancies_on_org_source"
    t.index ["organization_id", "unit_id", "status", "starts_at", "ends_at"], name: "index_unit_occupancies_on_org_unit_status_dates"
    t.index ["organization_id"], name: "index_unit_occupancies_on_organization_id"
    t.index ["person_id"], name: "index_unit_occupancies_on_person_id"
    t.index ["unit_id"], name: "index_unit_occupancies_on_unit_id"
  end

  create_table "unit_ownerships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "created_by_id"
    t.uuid "ended_by_id"
    t.date "ends_at"
    t.jsonb "metadata", default: {}, null: false
    t.uuid "organization_id", null: false
    t.decimal "ownership_percentage", precision: 5, scale: 2, default: "100.0", null: false
    t.uuid "person_id", null: false
    t.date "starts_at", null: false
    t.string "status", default: "active", null: false
    t.uuid "unit_id", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_unit_ownerships_on_created_by_id"
    t.index ["ended_by_id"], name: "index_unit_ownerships_on_ended_by_id"
    t.index ["metadata"], name: "index_unit_ownerships_on_metadata", using: :gin
    t.index ["organization_id", "person_id", "status"], name: "index_unit_ownerships_on_org_person_status"
    t.index ["organization_id", "unit_id", "starts_at", "ends_at"], name: "index_unit_ownerships_on_org_unit_date_range"
    t.index ["organization_id", "unit_id", "status"], name: "index_unit_ownerships_on_org_unit_status"
    t.index ["organization_id"], name: "index_unit_ownerships_on_organization_id"
    t.index ["person_id"], name: "index_unit_ownerships_on_person_id"
    t.index ["unit_id"], name: "index_unit_ownerships_on_unit_id"
  end

  create_table "units", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "area_m2", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.integer "floor_number"
    t.string "identifier", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "normalized_identifier", null: false
    t.uuid "organization_id", null: false
    t.uuid "property_section_id"
    t.uuid "residential_property_id", null: false
    t.string "status", default: "active", null: false
    t.string "unit_type", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_units_on_deleted_at"
    t.index ["metadata"], name: "index_units_on_metadata", using: :gin
    t.index ["organization_id", "property_section_id"], name: "index_units_on_organization_id_and_property_section_id"
    t.index ["organization_id", "residential_property_id", "property_section_id", "normalized_identifier"], name: "idx_units_unique_normalized_id_per_context", unique: true, where: "(deleted_at IS NULL)"
    t.index ["organization_id", "residential_property_id", "status"], name: "idx_on_organization_id_residential_property_id_stat_47cefd6e3a"
    t.index ["organization_id"], name: "index_units_on_organization_id"
    t.index ["property_section_id"], name: "index_units_on_property_section_id"
    t.index ["residential_property_id"], name: "index_units_on_residential_property_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "deactivated_at"
    t.datetime "deleted_at"
    t.string "dni"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "global_status", default: "active", null: false
    t.string "language"
    t.datetime "last_active_at"
    t.jsonb "metadata", default: {}, null: false
    t.string "name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "suspended_at"
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["deactivated_at"], name: "index_users_on_deactivated_at"
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["global_status"], name: "index_users_on_global_status"
    t.index ["metadata"], name: "index_users_on_metadata", using: :gin
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["suspended_at"], name: "index_users_on_suspended_at"
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.uuid "role_id"
    t.uuid "user_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
  end

  create_table "vehicles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "authorized_from"
    t.datetime "authorized_until"
    t.string "brand"
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.jsonb "metadata", default: {}, null: false
    t.string "model"
    t.uuid "organization_id", null: false
    t.uuid "person_id"
    t.text "plate_number_ciphertext"
    t.string "plate_number_digest"
    t.string "status", default: "active", null: false
    t.uuid "unit_id"
    t.datetime "updated_at", null: false
    t.string "vehicle_type"
    t.index ["organization_id"], name: "index_vehicles_on_organization_id"
    t.index ["person_id"], name: "index_vehicles_on_person_id"
    t.index ["unit_id"], name: "index_vehicles_on_unit_id"
  end

  create_table "visit_participants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "checked_in_at"
    t.datetime "checked_out_at"
    t.datetime "created_at", null: false
    t.string "document_snapshot_digest"
    t.jsonb "metadata", default: {}, null: false
    t.string "name_snapshot"
    t.text "notes"
    t.uuid "organization_id", null: false
    t.uuid "person_id"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.uuid "validated_by_id"
    t.uuid "visit_id", null: false
    t.uuid "visitor_profile_id"
    t.index ["metadata"], name: "index_visit_participants_on_metadata", using: :gin
    t.index ["organization_id", "person_id"], name: "index_visit_participants_on_organization_id_and_person_id"
    t.index ["organization_id", "visit_id", "status"], name: "idx_on_organization_id_visit_id_status_d1b6982805"
    t.index ["organization_id", "visitor_profile_id"], name: "idx_on_organization_id_visitor_profile_id_0adf418fb3"
    t.index ["organization_id"], name: "index_visit_participants_on_organization_id"
    t.index ["person_id"], name: "index_visit_participants_on_person_id"
    t.index ["validated_by_id"], name: "index_visit_participants_on_validated_by_id"
    t.index ["visit_id"], name: "index_visit_participants_on_visit_id"
    t.index ["visitor_profile_id"], name: "index_visit_participants_on_visitor_profile_id"
  end

  create_table "visit_status_histories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "changed_by_person_id"
    t.uuid "changed_by_user_id"
    t.datetime "created_at", null: false
    t.string "from_status"
    t.jsonb "metadata", default: {}, null: false
    t.uuid "organization_id", null: false
    t.text "reason"
    t.string "to_status", null: false
    t.datetime "updated_at", null: false
    t.uuid "visit_id", null: false
    t.index ["changed_by_person_id"], name: "index_visit_status_histories_on_changed_by_person_id"
    t.index ["changed_by_user_id"], name: "index_visit_status_histories_on_changed_by_user_id"
    t.index ["metadata"], name: "index_visit_status_histories_on_metadata", using: :gin
    t.index ["organization_id", "to_status"], name: "index_visit_status_histories_on_organization_id_and_to_status"
    t.index ["organization_id", "visit_id", "created_at"], name: "index_visit_status_histories_on_org_visit_created_at"
    t.index ["organization_id"], name: "index_visit_status_histories_on_organization_id"
    t.index ["visit_id"], name: "index_visit_status_histories_on_visit_id"
  end

  create_table "visitor_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "company_name"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "document_number_ciphertext"
    t.string "document_number_digest"
    t.string "document_type"
    t.text "email_ciphertext"
    t.string "external_name"
    t.jsonb "metadata", default: {}, null: false
    t.uuid "organization_id", null: false
    t.uuid "person_id"
    t.text "phone_ciphertext"
    t.text "security_notes"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_visitor_profiles_on_deleted_at"
    t.index ["metadata"], name: "index_visitor_profiles_on_metadata", using: :gin
    t.index ["organization_id", "document_number_digest"], name: "index_visitor_profiles_on_org_document_digest"
    t.index ["organization_id", "person_id"], name: "index_visitor_profiles_on_organization_id_and_person_id"
    t.index ["organization_id", "status"], name: "index_visitor_profiles_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_visitor_profiles_on_organization_id"
    t.index ["person_id"], name: "index_visitor_profiles_on_person_id"
  end

  create_table "visits", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "actual_ended_at"
    t.datetime "actual_started_at"
    t.datetime "approved_at"
    t.uuid "approved_by_id"
    t.string "authorization_method"
    t.datetime "concierge_validated_at"
    t.uuid "concierge_validated_by_id"
    t.datetime "created_at", null: false
    t.uuid "created_by_person_id"
    t.uuid "created_by_user_id"
    t.jsonb "metadata", default: {}, null: false
    t.text "notes"
    t.uuid "organization_id", null: false
    t.jsonb "recurring_rule", default: {}, null: false
    t.datetime "rejected_at"
    t.uuid "rejected_by_id"
    t.text "rejection_reason"
    t.uuid "residential_property_id", null: false
    t.uuid "responsible_person_id"
    t.datetime "scheduled_ends_at"
    t.datetime "scheduled_starts_at", null: false
    t.uuid "staff_shift_id"
    t.string "status", default: "pending", null: false
    t.uuid "unit_id", null: false
    t.datetime "updated_at", null: false
    t.index ["approved_by_id"], name: "index_visits_on_approved_by_id"
    t.index ["concierge_validated_by_id"], name: "index_visits_on_concierge_validated_by_id"
    t.index ["created_by_person_id"], name: "index_visits_on_created_by_person_id"
    t.index ["created_by_user_id"], name: "index_visits_on_created_by_user_id"
    t.index ["metadata"], name: "index_visits_on_metadata", using: :gin
    t.index ["organization_id", "residential_property_id", "scheduled_starts_at"], name: "index_visits_on_org_property_pending_statuses", where: "((status)::text = ANY ((ARRAY['pending'::character varying, 'concierge_validation_pending'::character varying, 'resident_notified'::character varying])::text[]))"
    t.index ["organization_id", "residential_property_id", "status", "scheduled_starts_at"], name: "index_visits_on_org_property_status_scheduled_starts"
    t.index ["organization_id", "staff_shift_id"], name: "index_visits_on_organization_id_and_staff_shift_id"
    t.index ["organization_id", "unit_id", "scheduled_starts_at"], name: "index_visits_on_org_unit_scheduled_starts"
    t.index ["organization_id"], name: "index_visits_on_organization_id"
    t.index ["recurring_rule"], name: "index_visits_on_recurring_rule", using: :gin
    t.index ["rejected_by_id"], name: "index_visits_on_rejected_by_id"
    t.index ["residential_property_id"], name: "index_visits_on_residential_property_id"
    t.index ["responsible_person_id"], name: "index_visits_on_responsible_person_id"
    t.index ["unit_id"], name: "index_visits_on_unit_id"
  end

  add_foreign_key "access_events", "organizations"
  add_foreign_key "access_events", "residential_properties"
  add_foreign_key "access_events", "units"
  add_foreign_key "access_events", "users", column: "recorded_by_user_id"
  add_foreign_key "access_events", "vehicles"
  add_foreign_key "access_events", "visit_participants"
  add_foreign_key "access_events", "visitor_profiles"
  add_foreign_key "access_events", "visits"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "authorized_residents", "organizations"
  add_foreign_key "authorized_residents", "people"
  add_foreign_key "authorized_residents", "people", column: "authorized_by_person_id"
  add_foreign_key "authorized_residents", "units"
  add_foreign_key "authorized_residents", "users", column: "authorized_by_user_id"
  add_foreign_key "lease_contracts", "organizations"
  add_foreign_key "lease_contracts", "people", column: "lessee_person_id"
  add_foreign_key "lease_contracts", "people", column: "lessor_person_id"
  add_foreign_key "lease_contracts", "units"
  add_foreign_key "lease_contracts", "users", column: "created_by_id"
  add_foreign_key "lease_contracts", "users", column: "terminated_by_id"
  add_foreign_key "organization_memberships", "organizations"
  add_foreign_key "organization_memberships", "people"
  add_foreign_key "people", "organizations"
  add_foreign_key "people", "users"
  add_foreign_key "people_roles", "people"
  add_foreign_key "people_roles", "roles"
  add_foreign_key "property_sections", "organizations"
  add_foreign_key "property_sections", "property_sections", column: "parent_id"
  add_foreign_key "property_sections", "residential_properties"
  add_foreign_key "property_setting_versions", "organizations"
  add_foreign_key "property_setting_versions", "property_settings"
  add_foreign_key "property_setting_versions", "residential_properties"
  add_foreign_key "property_setting_versions", "users", column: "changed_by_id"
  add_foreign_key "property_settings", "organizations"
  add_foreign_key "property_settings", "residential_properties"
  add_foreign_key "residential_properties", "organizations"
  add_foreign_key "roles", "organizations"
  add_foreign_key "unit_occupancies", "organizations"
  add_foreign_key "unit_occupancies", "people"
  add_foreign_key "unit_occupancies", "units"
  add_foreign_key "unit_ownerships", "organizations"
  add_foreign_key "unit_ownerships", "people"
  add_foreign_key "unit_ownerships", "units"
  add_foreign_key "unit_ownerships", "users", column: "created_by_id"
  add_foreign_key "unit_ownerships", "users", column: "ended_by_id"
  add_foreign_key "units", "organizations"
  add_foreign_key "units", "property_sections"
  add_foreign_key "units", "residential_properties"
  add_foreign_key "vehicles", "organizations"
  add_foreign_key "vehicles", "people"
  add_foreign_key "vehicles", "units"
  add_foreign_key "visit_participants", "organizations"
  add_foreign_key "visit_participants", "people"
  add_foreign_key "visit_participants", "users", column: "validated_by_id"
  add_foreign_key "visit_participants", "visitor_profiles"
  add_foreign_key "visit_participants", "visits"
  add_foreign_key "visit_status_histories", "organizations"
  add_foreign_key "visit_status_histories", "people", column: "changed_by_person_id"
  add_foreign_key "visit_status_histories", "users", column: "changed_by_user_id"
  add_foreign_key "visit_status_histories", "visits"
  add_foreign_key "visitor_profiles", "organizations"
  add_foreign_key "visitor_profiles", "people"
  add_foreign_key "visits", "organizations"
  add_foreign_key "visits", "people", column: "created_by_person_id"
  add_foreign_key "visits", "people", column: "responsible_person_id"
  add_foreign_key "visits", "residential_properties"
  add_foreign_key "visits", "units"
  add_foreign_key "visits", "users", column: "approved_by_id"
  add_foreign_key "visits", "users", column: "concierge_validated_by_id"
  add_foreign_key "visits", "users", column: "created_by_user_id"
  add_foreign_key "visits", "users", column: "rejected_by_id"
end
