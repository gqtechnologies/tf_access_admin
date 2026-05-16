# frozen_string_literal: true

# Partial unique indexes and query helpers for tenant-scoped lookups (see multi-tenancy audit).
class AddMultiTenantIndexesVehiclesVisitorProfilesVisitParticipants < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_index :vehicles, %i[organization_id plate_number_digest],
              unique: true,
              where: "((deleted_at IS NULL) AND (plate_number_digest IS NOT NULL))",
              name: "index_vehicles_unique_plate_digest_per_org_when_present",
              algorithm: :concurrently

    add_index :vehicles, %i[organization_id status],
              name: "index_vehicles_on_org_status",
              algorithm: :concurrently

    add_index :vehicles, %i[organization_id person_id],
              name: "index_vehicles_on_org_person",
              algorithm: :concurrently

    add_index :vehicles, %i[organization_id unit_id],
              name: "index_vehicles_on_org_unit",
              algorithm: :concurrently

    add_index :vehicles, :deleted_at,
              name: "index_vehicles_on_deleted_at",
              algorithm: :concurrently

    if index_exists?(:visitor_profiles, %i[organization_id document_number_digest],
                     name: "index_visitor_profiles_on_org_document_digest")
      remove_index :visitor_profiles,
                   name: "index_visitor_profiles_on_org_document_digest",
                   algorithm: :concurrently
    end

    add_index :visitor_profiles, %i[organization_id document_number_digest],
              unique: true,
              where: "((deleted_at IS NULL) AND (document_number_digest IS NOT NULL))",
              name: "index_visitor_profiles_unique_doc_digest_per_org_when_present",
              algorithm: :concurrently

    add_index :visit_participants, %i[organization_id document_snapshot_digest],
              name: "index_visit_participants_on_org_document_snapshot_digest",
              algorithm: :concurrently
  end

  def down
    remove_index :visit_participants,
                 name: "index_visit_participants_on_org_document_snapshot_digest",
                 algorithm: :concurrently,
                 if_exists: true

    remove_index :visitor_profiles,
                 name: "index_visitor_profiles_unique_doc_digest_per_org_when_present",
                 algorithm: :concurrently,
                 if_exists: true

    add_index :visitor_profiles, %i[organization_id document_number_digest],
              name: "index_visitor_profiles_on_org_document_digest",
              algorithm: :concurrently

    remove_index :vehicles, name: "index_vehicles_on_deleted_at", algorithm: :concurrently, if_exists: true
    remove_index :vehicles, name: "index_vehicles_on_org_unit", algorithm: :concurrently, if_exists: true
    remove_index :vehicles, name: "index_vehicles_on_org_person", algorithm: :concurrently, if_exists: true
    remove_index :vehicles, name: "index_vehicles_on_org_status", algorithm: :concurrently, if_exists: true
    remove_index :vehicles, name: "index_vehicles_unique_plate_digest_per_org_when_present",
                 algorithm: :concurrently,
                 if_exists: true
  end
end
