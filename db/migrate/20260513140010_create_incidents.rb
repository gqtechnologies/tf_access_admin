# frozen_string_literal: true

class CreateIncidents < ActiveRecord::Migration[8.1]
  def change
    create_table :incidents, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :residential_property, null: false, foreign_key: true, type: :uuid
      t.references :unit, foreign_key: true, type: :uuid
      t.references :common_area, foreign_key: true, type: :uuid
      t.references :visit, foreign_key: true, type: :uuid
      t.references :parcel_delivery, foreign_key: true, type: :uuid
      t.references :vehicle, foreign_key: true, type: :uuid
      t.references :reported_by_person, foreign_key: { to_table: :people }, type: :uuid
      t.references :assigned_to_person, foreign_key: { to_table: :people }, type: :uuid
      t.string :category, null: false
      t.string :priority, null: false, default: "normal"
      t.string :status, null: false, default: "open"
      t.text :description, null: false
      t.datetime :occurred_at
      t.datetime :resolved_at
      t.text :resolution
      t.jsonb :metadata, null: false, default: {}
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :incidents, %i[organization_id residential_property_id status priority occurred_at],
              name: "index_incidents_on_org_property_status_priority_occurred"
    add_index :incidents, %i[organization_id unit_id occurred_at]
    add_index :incidents, %i[organization_id assigned_to_person_id status],
              name: "index_incidents_on_org_assigned_person_status"
    add_index :incidents, %i[organization_id reported_by_person_id],
              name: "index_incidents_on_org_reported_by_person"
    add_index :incidents, :deleted_at
    add_index :incidents, :metadata, using: :gin
  end
end
