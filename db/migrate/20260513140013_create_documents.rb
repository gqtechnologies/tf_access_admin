# frozen_string_literal: true

class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.string :documentable_type, null: false
      t.bigint :documentable_id, null: false
      t.references :uploaded_by_person, foreign_key: { to_table: :people }, type: :uuid
      t.string :category, null: false
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: "pending"
      t.string :visibility, null: false, default: "private"
      t.datetime :expires_at
      t.boolean :sensitive, null: false, default: false
      t.jsonb :metadata, null: false, default: {}
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :documents, %i[organization_id documentable_type documentable_id],
              name: "index_documents_on_org_documentable"
    add_index :documents, %i[organization_id uploaded_by_person_id],
              name: "index_documents_on_org_uploaded_by_person"
    add_index :documents, %i[organization_id status expires_at],
              name: "index_documents_on_org_status_expires_at"
    add_index :documents, %i[organization_id category]
    add_index :documents, %i[organization_id sensitive]
    add_index :documents, :deleted_at
    add_index :documents, :metadata, using: :gin
  end
end
