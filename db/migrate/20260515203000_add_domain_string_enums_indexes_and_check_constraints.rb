# frozen_string_literal: true

# §7: extra tenant/query indexes, drop redundant org membership index, and CHECK constraints (§7.3).
class AddDomainStringEnumsIndexesAndCheckConstraints < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    remove_index :organization_memberships,
                 name: "idx_on_organization_id_person_id_cd1ad4bbc4",
                 if_exists: true

    unless index_exists?(:audits, %i[auditable_type auditable_id organization_id version],
                         name: "index_audits_on_auditable_org_version")
      add_index :audits,
                %i[auditable_type auditable_id organization_id version],
                name: "index_audits_on_auditable_org_version",
                algorithm: :concurrently
    end

    unless index_exists?(:notifications, %i[organization_id recipient_person_id read_at],
                         name: "index_notifications_on_org_recipient_read_at")
      add_index :notifications,
                %i[organization_id recipient_person_id read_at],
                name: "index_notifications_on_org_recipient_read_at",
                algorithm: :concurrently
    end

    unless index_exists?(:lease_contracts, %i[organization_id status ends_at],
                         name: "index_lease_contracts_on_org_status_ends_at")
      add_index :lease_contracts,
                %i[organization_id status ends_at],
                name: "index_lease_contracts_on_org_status_ends_at",
                algorithm: :concurrently
    end

    unless index_exists?(:staff_shifts, %i[organization_id residential_property_id status],
                         name: "index_staff_shifts_on_org_property_in_progress")
      add_index :staff_shifts,
                %i[organization_id residential_property_id status],
                name: "index_staff_shifts_on_org_property_in_progress",
                where: "((status)::text = 'in_progress'::text)",
                algorithm: :concurrently
    end

    apply_check_constraints!
  end

  def down
    remove_check_constraint :visit_participants, name: "visit_participants_identity_present", if_exists: true
    remove_check_constraint :authorized_residents, name: "authorized_residents_date_range_valid", if_exists: true
    remove_check_constraint :unit_occupancies, name: "unit_occupancies_date_range_valid", if_exists: true
    remove_check_constraint :unit_ownerships, name: "unit_ownerships_percentage_range", if_exists: true
    remove_check_constraint :unit_ownerships, name: "unit_ownerships_date_range_valid", if_exists: true
    remove_check_constraint :lease_contracts, name: "lease_contracts_date_range_valid", if_exists: true
    remove_check_constraint :visits, name: "visits_scheduled_range_valid", if_exists: true
    remove_check_constraint :parcel_deliveries, name: "parcel_deliveries_withdrawn_after_received", if_exists: true

    remove_index :staff_shifts,
                 name: "index_staff_shifts_on_org_property_in_progress",
                 algorithm: :concurrently,
                 if_exists: true
    remove_index :lease_contracts,
                 name: "index_lease_contracts_on_org_status_ends_at",
                 algorithm: :concurrently,
                 if_exists: true
    remove_index :notifications,
                 name: "index_notifications_on_org_recipient_read_at",
                 algorithm: :concurrently,
                 if_exists: true
    remove_index :audits,
                 name: "index_audits_on_auditable_org_version",
                 algorithm: :concurrently,
                 if_exists: true

    add_index :organization_memberships,
              %i[organization_id person_id],
              name: "idx_on_organization_id_person_id_cd1ad4bbc4",
              algorithm: :concurrently,
              if_not_exists: true
  end

  private

  def apply_check_constraints!
    add_check_constraint :parcel_deliveries,
                         "withdrawn_at IS NULL OR withdrawn_at >= received_at",
                         name: "parcel_deliveries_withdrawn_after_received",
                         validate: false
    add_check_constraint :visits,
                         "scheduled_ends_at IS NULL OR scheduled_ends_at >= scheduled_starts_at",
                         name: "visits_scheduled_range_valid",
                         validate: false
    add_check_constraint :lease_contracts,
                         "ends_at IS NULL OR ends_at >= starts_at",
                         name: "lease_contracts_date_range_valid",
                         validate: false
    add_check_constraint :unit_ownerships,
                         "ends_at IS NULL OR ends_at >= starts_at",
                         name: "unit_ownerships_date_range_valid",
                         validate: false
    add_check_constraint :unit_ownerships,
                         "ownership_percentage > 0 AND ownership_percentage <= 100",
                         name: "unit_ownerships_percentage_range",
                         validate: false
    add_check_constraint :unit_occupancies,
                         "ends_at IS NULL OR ends_at >= starts_at",
                         name: "unit_occupancies_date_range_valid",
                         validate: false
    add_check_constraint :authorized_residents,
                         "ends_at IS NULL OR ends_at >= starts_at",
                         name: "authorized_residents_date_range_valid",
                         validate: false
    add_check_constraint :visit_participants,
                         "(person_id IS NOT NULL) OR (visitor_profile_id IS NOT NULL) OR (name_snapshot IS NOT NULL)",
                         name: "visit_participants_identity_present",
                         validate: false

    validate_check_constraint :parcel_deliveries, name: "parcel_deliveries_withdrawn_after_received"
    validate_check_constraint :visits, name: "visits_scheduled_range_valid"
    validate_check_constraint :lease_contracts, name: "lease_contracts_date_range_valid"
    validate_check_constraint :unit_ownerships, name: "unit_ownerships_date_range_valid"
    validate_check_constraint :unit_ownerships, name: "unit_ownerships_percentage_range"
    validate_check_constraint :unit_occupancies, name: "unit_occupancies_date_range_valid"
    validate_check_constraint :authorized_residents, name: "authorized_residents_date_range_valid"
    validate_check_constraint :visit_participants, name: "visit_participants_identity_present"
  end
end
