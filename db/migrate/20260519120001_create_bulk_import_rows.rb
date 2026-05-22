# frozen_string_literal: true

class CreateBulkImportRows < ActiveRecord::Migration[8.1]
  def change
    create_table :bulk_import_rows, id: :uuid do |t|
      t.references :bulk_import, null: false, foreign_key: true, type: :uuid

      t.integer :row_number, null: false
      t.string :sheet_name
      t.string :group_key
      t.string :operation

      t.string :validation_status, null: false, default: "pending"
      t.string :import_status, null: false, default: "pending"

      t.jsonb :raw_payload, null: false, default: {}
      t.jsonb :normalized_payload, null: false, default: {}
      t.jsonb :validation_errors, null: false, default: []
      t.jsonb :validation_warnings, null: false, default: []

      t.string :target_record_type
      t.uuid :target_record_id

      t.text :failure_message

      t.datetime :validated_at
      t.datetime :imported_at
      t.datetime :failed_at
      t.datetime :skipped_at

      t.timestamps
    end

    add_index :bulk_import_rows, %i[bulk_import_id row_number], unique: true
    add_index :bulk_import_rows, %i[bulk_import_id validation_status]
    add_index :bulk_import_rows, %i[bulk_import_id import_status]
    add_index :bulk_import_rows, %i[bulk_import_id group_key]
    add_index :bulk_import_rows, %i[target_record_type target_record_id]
    add_index :bulk_import_rows, :row_number
    add_index :bulk_import_rows, :raw_payload, using: :gin
    add_index :bulk_import_rows, :normalized_payload, using: :gin
  end
end
