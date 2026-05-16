# frozen_string_literal: true

# Replaces user-scoped actor columns with person-scoped ones on tenant tables.
# Data loss is acceptable (empty DB / no backfill). See project rule: obtain
# User via `record.some_person.user` when needed.
class UsePersonForTenantActorForeignKeys < ActiveRecord::Migration[8.1]
  def up
    # --- visits ---
    remove_reference :visits, :created_by_user, type: :uuid, foreign_key: { to_table: :users }
    remove_reference :visits, :approved_by, type: :uuid, foreign_key: { to_table: :users }
    remove_reference :visits, :concierge_validated_by, type: :uuid, foreign_key: { to_table: :users }
    remove_reference :visits, :rejected_by, type: :uuid, foreign_key: { to_table: :users }

    add_reference :visits, :approved_by_person,
                  type: :uuid, null: true, foreign_key: { to_table: :people }
    add_reference :visits, :concierge_validated_by_person,
                  type: :uuid, null: true, foreign_key: { to_table: :people }
    add_reference :visits, :rejected_by_person,
                  type: :uuid, null: true, foreign_key: { to_table: :people }

    # --- visit_status_histories ---
    remove_reference :visit_status_histories, :changed_by_user,
                     type: :uuid, foreign_key: { to_table: :users }

    # --- authorized_residents ---
    remove_reference :authorized_residents, :authorized_by_user,
                     type: :uuid, foreign_key: { to_table: :users }

    # --- visit_participants ---
    remove_reference :visit_participants, :validated_by,
                     type: :uuid, foreign_key: { to_table: :users }
    add_reference :visit_participants, :validated_by_person,
                  type: :uuid, null: true, foreign_key: { to_table: :people }

    # --- lease_contracts ---
    remove_reference :lease_contracts, :created_by,
                     type: :uuid, foreign_key: { to_table: :users }
    remove_reference :lease_contracts, :terminated_by,
                     type: :uuid, foreign_key: { to_table: :users }
    add_reference :lease_contracts, :created_by_person,
                  type: :uuid, null: true, foreign_key: { to_table: :people }
    add_reference :lease_contracts, :terminated_by_person,
                  type: :uuid, null: true, foreign_key: { to_table: :people }

    # --- unit_ownerships ---
    remove_reference :unit_ownerships, :created_by,
                     type: :uuid, foreign_key: { to_table: :users }
    remove_reference :unit_ownerships, :ended_by,
                     type: :uuid, foreign_key: { to_table: :users }
    add_reference :unit_ownerships, :created_by_person,
                  type: :uuid, null: true, foreign_key: { to_table: :people }
    add_reference :unit_ownerships, :ended_by_person,
                  type: :uuid, null: true, foreign_key: { to_table: :people }

    # --- property_setting_versions ---
    remove_reference :property_setting_versions, :changed_by,
                     type: :uuid, foreign_key: { to_table: :users }
    add_reference :property_setting_versions, :changed_by_person,
                  type: :uuid, null: true, foreign_key: { to_table: :people }

    # --- access_events ---
    remove_reference :access_events, :recorded_by_user,
                     type: :uuid, foreign_key: { to_table: :users }
    add_reference :access_events, :recorded_by_person,
                  type: :uuid, null: true, foreign_key: { to_table: :people }
  end

  def down
    remove_reference :access_events, :recorded_by_person,
                     type: :uuid, foreign_key: { to_table: :people }
    add_reference :access_events, :recorded_by_user,
                  type: :uuid, null: true, foreign_key: { to_table: :users }

    remove_reference :property_setting_versions, :changed_by_person,
                     type: :uuid, foreign_key: { to_table: :people }
    add_reference :property_setting_versions, :changed_by,
                  type: :uuid, null: true, foreign_key: { to_table: :users }

    remove_reference :unit_ownerships, :ended_by_person,
                     type: :uuid, foreign_key: { to_table: :people }
    remove_reference :unit_ownerships, :created_by_person,
                     type: :uuid, foreign_key: { to_table: :people }
    add_reference :unit_ownerships, :ended_by,
                  type: :uuid, null: true, foreign_key: { to_table: :users }
    add_reference :unit_ownerships, :created_by,
                  type: :uuid, null: true, foreign_key: { to_table: :users }

    remove_reference :lease_contracts, :terminated_by_person,
                     type: :uuid, foreign_key: { to_table: :people }
    remove_reference :lease_contracts, :created_by_person,
                     type: :uuid, foreign_key: { to_table: :people }
    add_reference :lease_contracts, :terminated_by,
                  type: :uuid, null: true, foreign_key: { to_table: :users }
    add_reference :lease_contracts, :created_by,
                  type: :uuid, null: true, foreign_key: { to_table: :users }

    remove_reference :visit_participants, :validated_by_person,
                     type: :uuid, foreign_key: { to_table: :people }
    add_reference :visit_participants, :validated_by,
                  type: :uuid, null: true, foreign_key: { to_table: :users }

    add_reference :authorized_residents, :authorized_by_user,
                  type: :uuid, null: true, foreign_key: { to_table: :users }, index: false

    add_reference :visit_status_histories, :changed_by_user,
                  type: :uuid, null: true, foreign_key: { to_table: :users }

    remove_reference :visits, :rejected_by_person,
                     type: :uuid, foreign_key: { to_table: :people }
    remove_reference :visits, :concierge_validated_by_person,
                     type: :uuid, foreign_key: { to_table: :people }
    remove_reference :visits, :approved_by_person,
                     type: :uuid, foreign_key: { to_table: :people }

    add_reference :visits, :rejected_by,
                  type: :uuid, null: true, foreign_key: { to_table: :users }
    add_reference :visits, :concierge_validated_by,
                  type: :uuid, null: true, foreign_key: { to_table: :users }
    add_reference :visits, :approved_by,
                  type: :uuid, null: true, foreign_key: { to_table: :users }
    add_reference :visits, :created_by_user,
                  type: :uuid, null: true, foreign_key: { to_table: :users }
  end
end
