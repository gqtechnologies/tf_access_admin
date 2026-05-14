# frozen_string_literal: true

class CreateAnnouncementReads < ActiveRecord::Migration[8.1]
  def change
    create_table :announcement_reads, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :announcement, null: false, foreign_key: true, type: :uuid
      t.references :person, foreign_key: { to_table: :people }, type: :uuid
      t.datetime :read_at
      t.string :channel
      t.datetime :notified_at
      t.datetime :acknowledged_at
      t.jsonb :device_info, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :announcement_reads, %i[organization_id announcement_id person_id],
              unique: true,
              where: "person_id IS NOT NULL",
              name: "index_announcement_reads_unique_per_person_when_present"
    add_index :announcement_reads, %i[organization_id announcement_id read_at],
              name: "index_announcement_reads_on_org_announcement_read_at"
    add_index :announcement_reads, %i[organization_id person_id read_at],
              name: "index_announcement_reads_on_org_person_read_at"
    add_index :announcement_reads, :metadata, using: :gin
    add_index :announcement_reads, :device_info, using: :gin
  end
end
