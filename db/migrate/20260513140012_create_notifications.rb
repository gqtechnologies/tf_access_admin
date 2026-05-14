# frozen_string_literal: true

class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :residential_property, foreign_key: true, type: :uuid
      t.references :unit, foreign_key: true, type: :uuid
      t.references :recipient_person, null: false, foreign_key: { to_table: :people }, type: :uuid
      t.string :notification_type, null: false
      t.string :channel, null: false
      t.string :status, null: false, default: "pending"
      t.string :notifiable_type, null: false
      t.bigint :notifiable_id, null: false
      t.datetime :sent_at
      t.datetime :read_at
      t.integer :attempts_count, null: false, default: 0
      t.text :last_error
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :notifications, %i[organization_id recipient_person_id status created_at],
              name: "index_notifications_on_org_recipient_status_created_at"
    add_index :notifications, %i[organization_id notifiable_type notifiable_id],
              name: "index_notifications_on_org_notifiable"
    add_index :notifications, %i[organization_id channel status created_at],
              name: "index_notifications_on_org_channel_pending_status",
              where: "status = 'pending'"
    add_index :notifications, :metadata, using: :gin
  end
end
