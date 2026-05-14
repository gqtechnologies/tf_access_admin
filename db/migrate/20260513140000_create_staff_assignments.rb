# frozen_string_literal: true

class CreateStaffAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :staff_assignments, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :person, null: false, foreign_key: { to_table: :people }, type: :uuid
      t.references :residential_property, null: false, foreign_key: true, type: :uuid
      t.string :staff_type, null: false
      t.date :starts_at
      t.date :ends_at
      t.string :status, null: false, default: "active"
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :staff_assignments, %i[organization_id residential_property_id staff_type status],
              name: "index_staff_assignments_on_org_property_type_status"
    add_index :staff_assignments, %i[organization_id person_id status]
    add_index :staff_assignments, :metadata, using: :gin
  end
end
