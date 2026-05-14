# frozen_string_literal: true

class CreatePropertySections < ActiveRecord::Migration[8.1]
  def up
    return if table_exists?(:property_sections)

    create_table :property_sections, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :residential_property, null: false, foreign_key: true, type: :uuid
      t.references :parent, foreign_key: { to_table: :property_sections }, type: :uuid, null: true
      t.string :section_type, null: false
      t.string :name, null: false
      t.string :code
      t.integer :position
      t.jsonb :metadata, null: false, default: {}
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :property_sections, %i[organization_id residential_property_id parent_id],
              name: "index_property_sections_on_org_property_parent"

    add_index :property_sections,
              %i[organization_id residential_property_id parent_id section_type code],
              unique: true,
              where: "code IS NOT NULL AND deleted_at IS NULL",
              name: "index_property_sections_on_org_property_parent_type_code_active"

    add_index :property_sections, :deleted_at
    add_index :property_sections, :metadata, using: :gin
  end

  def down
    drop_table :property_sections, if_exists: true
  end
end
