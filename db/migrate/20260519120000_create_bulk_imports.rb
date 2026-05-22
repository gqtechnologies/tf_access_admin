# frozen_string_literal: true

class CreateBulkImports < ActiveRecord::Migration[8.1]
  def change
    create_table :bulk_imports, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :created_by, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :residential_property, foreign_key: true, type: :uuid
      t.references :property_section, foreign_key: true, type: :uuid

      t.string :import_type, null: false
      t.string :status, null: false, default: "draft"

      t.string :original_filename
      t.string :content_type
      t.bigint :file_size
      t.string :file_checksum

      t.integer :total_rows, null: false, default: 0
      t.integer :valid_rows, null: false, default: 0
      t.integer :warning_rows, null: false, default: 0
      t.integer :error_rows, null: false, default: 0
      t.integer :imported_rows, null: false, default: 0
      t.integer :failed_rows, null: false, default: 0
      t.integer :skipped_rows, null: false, default: 0

      t.jsonb :metadata, null: false, default: {}
      t.jsonb :summary, null: false, default: {}

      t.datetime :validated_at
      t.datetime :confirmed_at
      t.datetime :processing_started_at
      t.datetime :finished_at
      t.datetime :cancelled_at
      t.datetime :expires_at

      t.text :failure_message

      t.timestamps
    end

    add_index :bulk_imports, %i[organization_id status]
    add_index :bulk_imports, %i[organization_id import_type]
    add_index :bulk_imports, %i[organization_id created_at]
    add_index :bulk_imports, :status
    add_index :bulk_imports, :import_type
    add_index :bulk_imports, :expires_at
    add_index :bulk_imports, :file_checksum
    add_index :bulk_imports, :created_at
    add_index :bulk_imports, :metadata, using: :gin
    add_index :bulk_imports, :summary, using: :gin
  end
end
