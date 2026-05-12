# frozen_string_literal: true

class CreateResidentialProperties < ActiveRecord::Migration[8.1]
  def change
    create_table :residential_properties, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :code
      t.string :property_type, null: false
      t.string :address_line
      t.string :city
      t.string :region
      t.string :country, default: "Chile"
      t.string :timezone, default: "America/Santiago"
      t.string :status, null: false, default: "active"
      t.jsonb :metadata, null: false, default: {}
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :residential_properties, %i[organization_id code],
              unique: true,
              where: "code IS NOT NULL AND deleted_at IS NULL",
              name: "index_residential_properties_on_org_id_and_code_active"
    add_index :residential_properties, %i[organization_id property_type]
    add_index :residential_properties, %i[organization_id status]
    add_index :residential_properties, :deleted_at
    add_index :residential_properties, :metadata, using: :gin
  end
end
