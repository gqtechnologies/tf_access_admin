# frozen_string_literal: true

class CreateUnitOwnerships < ActiveRecord::Migration[8.1]
  def change
    create_table :unit_ownerships, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :unit, null: false, foreign_key: true, type: :uuid
      t.references :person, null: false, foreign_key: { to_table: :people }, type: :uuid
      t.decimal :ownership_percentage, precision: 5, scale: 2, null: false, default: "100.0"
      t.date :starts_at, null: false
      t.date :ends_at
      t.string :status, null: false, default: "active"
      t.references :created_by, foreign_key: { to_table: :users }, type: :uuid, null: true
      t.references :ended_by, foreign_key: { to_table: :users }, type: :uuid, null: true
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :unit_ownerships, %i[organization_id unit_id starts_at ends_at],
              name: "index_unit_ownerships_on_org_unit_date_range"
    add_index :unit_ownerships, %i[organization_id person_id status],
              name: "index_unit_ownerships_on_org_person_status"
    add_index :unit_ownerships, %i[organization_id unit_id status],
              name: "index_unit_ownerships_on_org_unit_status"
    add_index :unit_ownerships, :metadata, using: :gin
  end
end
