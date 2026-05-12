# frozen_string_literal: true

class CreateUnitOccupancies < ActiveRecord::Migration[8.1]
  def change
    create_table :unit_occupancies, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :unit, null: false, foreign_key: true, type: :uuid
      t.references :person, null: false, foreign_key: { to_table: :people }, type: :uuid
      t.string :occupancy_type, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at
      t.string :status, null: false, default: "active"
      t.string :source_type
      t.bigint :source_id
      t.boolean :can_authorize_visits, null: false, default: false
      t.boolean :can_withdraw_parcels, null: false, default: false
      t.boolean :can_reserve_common_areas, null: false, default: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :unit_occupancies, %i[organization_id unit_id status starts_at ends_at],
              name: "index_unit_occupancies_on_org_unit_status_dates"
    add_index :unit_occupancies, %i[organization_id person_id status],
              name: "index_unit_occupancies_on_org_person_status"
    add_index :unit_occupancies, %i[organization_id source_type source_id],
              name: "index_unit_occupancies_on_org_source"
    add_index :unit_occupancies, :metadata, using: :gin
  end
end
