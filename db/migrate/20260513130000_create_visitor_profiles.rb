# frozen_string_literal: true

class CreateVisitorProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :visitor_profiles, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :person, foreign_key: { to_table: :people }, type: :uuid
      t.string :external_name
      t.string :document_type
      t.text :document_number_ciphertext
      t.string :document_number_digest
      t.text :phone_ciphertext
      t.text :email_ciphertext
      t.string :company_name
      t.string :status, null: false, default: "active"
      t.text :security_notes
      t.jsonb :metadata, null: false, default: {}
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :visitor_profiles, %i[organization_id status]
    add_index :visitor_profiles, %i[organization_id document_number_digest],
              name: "index_visitor_profiles_on_org_document_digest"
    add_index :visitor_profiles, %i[organization_id person_id]
    add_index :visitor_profiles, :deleted_at
    add_index :visitor_profiles, :metadata, using: :gin
  end
end
