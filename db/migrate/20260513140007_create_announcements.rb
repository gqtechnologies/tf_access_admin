# frozen_string_literal: true

class CreateAnnouncements < ActiveRecord::Migration[8.1]
  def change
    create_table :announcements, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :residential_property, null: false, foreign_key: true, type: :uuid
      t.references :author_person, null: false, foreign_key: { to_table: :people }, type: :uuid
      t.string :title, null: false
      t.text :content, null: false
      t.string :status, null: false, default: "draft"
      t.string :priority, null: false, default: "normal"
      t.string :category
      t.datetime :published_at
      t.datetime :expires_at
      t.boolean :requires_acknowledgement, default: false
      t.jsonb :metadata, null: false, default: {}
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :announcements, %i[organization_id residential_property_id status published_at],
              name: "index_announcements_on_org_property_status_published_at"
    add_index :announcements, %i[organization_id author_person_id]
    add_index :announcements, %i[organization_id priority]
    add_index :announcements, :deleted_at
    add_index :announcements, :metadata, using: :gin
  end
end
