# frozen_string_literal: true

class CreateCommonAreas < ActiveRecord::Migration[8.1]
  def change
    create_table :common_areas, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :residential_property, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :area_type, null: false
      t.integer :capacity
      t.boolean :requires_approval, null: false, default: true
      t.string :status, null: false, default: "active"
      t.jsonb :rules, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :common_areas, %i[organization_id residential_property_id status]
    add_index :common_areas, %i[organization_id residential_property_id name],
              unique: true,
              where: "deleted_at IS NULL",
              name: "index_common_areas_unique_name_per_property_when_active"
    add_index :common_areas, :deleted_at
    add_index :common_areas, :rules, using: :gin
    add_index :common_areas, :metadata, using: :gin
  end
end
