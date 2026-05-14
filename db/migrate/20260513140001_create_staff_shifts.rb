# frozen_string_literal: true

class CreateStaffShifts < ActiveRecord::Migration[8.1]
  def change
    create_table :staff_shifts, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :residential_property, null: false, foreign_key: true, type: :uuid
      t.references :staff_assignment, null: false, foreign_key: true, type: :uuid
      t.references :person, null: false, foreign_key: { to_table: :people }, type: :uuid
      t.datetime :planned_starts_at, null: false
      t.datetime :planned_ends_at, null: false
      t.datetime :actual_starts_at
      t.datetime :actual_ends_at
      t.string :status, null: false, default: "scheduled"
      t.uuid :replaced_by_shift_id
      t.references :opened_by_person, foreign_key: { to_table: :people }, type: :uuid
      t.references :closed_by_person, foreign_key: { to_table: :people }, type: :uuid
      t.text :notes
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_foreign_key :staff_shifts, :staff_shifts, column: :replaced_by_shift_id

    add_index :staff_shifts, %i[organization_id residential_property_id planned_starts_at planned_ends_at],
              name: "index_staff_shifts_on_org_property_planned_range"
    add_index :staff_shifts, %i[organization_id person_id planned_starts_at planned_ends_at],
              name: "index_staff_shifts_on_org_person_planned_range"
    add_index :staff_shifts, %i[organization_id status]
    add_index :staff_shifts, :metadata, using: :gin

    add_check_constraint :staff_shifts, "planned_ends_at >= planned_starts_at",
                         name: "staff_shifts_planned_range_valid"
  end
end
