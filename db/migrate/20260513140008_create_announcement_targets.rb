# frozen_string_literal: true

class CreateAnnouncementTargets < ActiveRecord::Migration[8.1]
  def change
    create_table :announcement_targets, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :announcement, null: false, foreign_key: true, type: :uuid
      t.string :target_type, null: false
      t.bigint :target_id, null: false
      t.jsonb :target_rule, null: false, default: {}

      t.timestamps
    end

    add_index :announcement_targets, %i[organization_id announcement_id]
    add_index :announcement_targets, %i[organization_id target_type target_id],
              name: "index_announcement_targets_on_org_target"
    add_index :announcement_targets, :target_rule, using: :gin
  end
end
