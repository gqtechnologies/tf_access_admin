# frozen_string_literal: true

class CreatePropertySettingVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :property_setting_versions, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :residential_property, null: false, foreign_key: true, type: :uuid
      t.references :property_setting, null: false, foreign_key: true, type: :uuid
      t.integer :version_number, null: false
      t.jsonb :snapshot, null: false, default: {}
      t.references :changed_by, foreign_key: { to_table: :users }, type: :uuid, null: true
      t.text :change_reason

      t.timestamps
    end

    add_index :property_setting_versions,
              %i[organization_id residential_property_id version_number],
              name: "index_property_setting_versions_on_org_property_version"

    add_index :property_setting_versions, %i[organization_id property_setting_id],
              name: "index_property_setting_versions_on_org_and_setting"

    add_index :property_setting_versions, :snapshot, using: :gin
  end
end
