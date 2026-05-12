# frozen_string_literal: true

class CreateUnits < ActiveRecord::Migration[8.1]
  def change
    create_table :units, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :residential_property, null: false, foreign_key: true, type: :uuid
      t.references :property_section, foreign_key: true, type: :uuid, null: true
      t.string :unit_type, null: false
      t.string :identifier, null: false
      t.string :normalized_identifier, null: false
      t.string :display_name
      t.string :status, null: false, default: "active"
      t.decimal :area_m2, precision: 10, scale: 2
      t.jsonb :metadata, null: false, default: {}
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :units,
              %i[organization_id residential_property_id property_section_id normalized_identifier],
              unique: true,
              where: "property_section_id IS NOT NULL AND deleted_at IS NULL",
              name: "index_units_on_org_property_section_normalized_when_section"

    add_index :units,
              %i[organization_id residential_property_id normalized_identifier],
              unique: true,
              where: "property_section_id IS NULL AND deleted_at IS NULL",
              name: "index_units_on_org_property_normalized_when_no_section"

    add_index :units, %i[organization_id residential_property_id status]
    add_index :units, %i[organization_id property_section_id]
    add_index :units, :deleted_at
    add_index :units, :metadata, using: :gin
  end
end
