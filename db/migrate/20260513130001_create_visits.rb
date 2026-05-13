# frozen_string_literal: true

class CreateVisits < ActiveRecord::Migration[8.1]
  def change
    create_table :visits, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :residential_property, null: false, foreign_key: true, type: :uuid
      t.references :unit, null: false, foreign_key: true, type: :uuid
      t.references :created_by_user, foreign_key: { to_table: :users }, type: :uuid
      t.references :created_by_person, foreign_key: { to_table: :people }, type: :uuid
      t.references :responsible_person, foreign_key: { to_table: :people }, type: :uuid
      t.datetime :scheduled_starts_at, null: false
      t.datetime :scheduled_ends_at
      t.datetime :actual_started_at
      t.datetime :actual_ended_at
      t.string :status, null: false, default: "pending"
      t.string :authorization_method
      t.jsonb :recurring_rule, null: false, default: {}
      t.references :concierge_validated_by, foreign_key: { to_table: :users }, type: :uuid
      t.datetime :concierge_validated_at
      t.references :approved_by, foreign_key: { to_table: :users }, type: :uuid
      t.datetime :approved_at
      t.references :rejected_by, foreign_key: { to_table: :users }, type: :uuid
      t.datetime :rejected_at
      t.text :rejection_reason
      t.uuid :staff_shift_id
      t.text :notes
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :visits, %i[organization_id residential_property_id status scheduled_starts_at],
              name: "index_visits_on_org_property_status_scheduled_starts"
    add_index :visits, %i[organization_id unit_id scheduled_starts_at],
              name: "index_visits_on_org_unit_scheduled_starts"
    add_index :visits, %i[organization_id staff_shift_id]
    add_index :visits, %i[organization_id residential_property_id scheduled_starts_at],
              name: "index_visits_on_org_property_pending_statuses",
              where: "status IN ('pending', 'concierge_validation_pending', 'resident_notified')"
    add_index :visits, :metadata, using: :gin
    add_index :visits, :recurring_rule, using: :gin
  end
end
