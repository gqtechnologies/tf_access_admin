# frozen_string_literal: true

class CreatePropertySettings < ActiveRecord::Migration[8.1]
  def up
    return if table_exists?(:property_settings)

    create_table :property_settings, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :residential_property, null: false, foreign_key: true, type: :uuid

      t.boolean :visit_requires_concierge_validation, null: false, default: true
      t.boolean :visit_requires_resident_approval, null: false, default: true
      t.boolean :concierge_can_approve_visits, null: false, default: false
      t.integer :max_simultaneous_visitors_per_unit, null: false, default: 5
      t.integer :max_visitors_per_visit, null: false, default: 5
      t.boolean :allow_recurring_visits, null: false, default: false
      t.boolean :visitor_identity_document_required, null: false, default: false
      t.boolean :vehicle_plate_required, null: false, default: false
      t.boolean :parcel_requires_signature, null: false, default: false
      t.boolean :reservation_requires_approval, null: false, default: true
      t.integer :max_reservations_per_month
      t.integer :reservation_min_advance_hours, null: false, default: 0
      t.integer :reservation_max_duration_minutes
      t.jsonb :active_notification_channels, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :property_settings, %i[organization_id residential_property_id], unique: true
    add_index :property_settings, :metadata, using: :gin
    add_index :property_settings, :active_notification_channels, using: :gin
  end

  def down
    drop_table :property_settings, if_exists: true
  end
end
