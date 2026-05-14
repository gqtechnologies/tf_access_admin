# frozen_string_literal: true

class CreateParcelDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :parcel_deliveries, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :residential_property, null: false, foreign_key: true, type: :uuid
      t.references :unit, null: false, foreign_key: true, type: :uuid
      t.references :recipient_person, foreign_key: { to_table: :people }, type: :uuid
      t.string :delivery_type, null: false, default: "parcel"
      t.string :courier_company
      t.string :tracking_code
      t.references :received_by_person, foreign_key: { to_table: :people }, type: :uuid
      t.datetime :received_at, null: false
      t.datetime :notified_at
      t.references :withdrawn_by_person, foreign_key: { to_table: :people }, type: :uuid
      t.datetime :withdrawn_at
      t.references :staff_shift, foreign_key: true, type: :uuid
      t.string :status, null: false, default: "received"
      t.text :notes
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :parcel_deliveries, %i[organization_id unit_id status received_at],
              name: "index_parcel_deliveries_on_org_unit_status_received_at"
    add_index :parcel_deliveries, %i[organization_id residential_property_id status received_at],
              name: "index_parcel_deliveries_on_org_property_status_received_at"
    add_index :parcel_deliveries, %i[organization_id tracking_code],
              name: "index_parcel_deliveries_on_org_tracking_code"
    add_index :parcel_deliveries, %i[organization_id staff_shift_id]
    add_index :parcel_deliveries, %i[organization_id received_by_person_id],
              name: "index_parcel_deliveries_on_org_received_by_person"
    add_index :parcel_deliveries, %i[organization_id withdrawn_by_person_id],
              name: "index_parcel_deliveries_on_org_withdrawn_by_person"
    add_index :parcel_deliveries, :metadata, using: :gin
  end
end
