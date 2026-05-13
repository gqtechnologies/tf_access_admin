# frozen_string_literal: true

class CreateVisitStatusHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :visit_status_histories, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :visit, null: false, foreign_key: true, type: :uuid
      t.string :from_status
      t.string :to_status, null: false
      t.references :changed_by_user, foreign_key: { to_table: :users }, type: :uuid
      t.references :changed_by_person, foreign_key: { to_table: :people }, type: :uuid
      t.text :reason
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :visit_status_histories, %i[organization_id visit_id created_at],
              name: "index_visit_status_histories_on_org_visit_created_at"
    add_index :visit_status_histories, %i[organization_id to_status]
    add_index :visit_status_histories, :metadata, using: :gin
  end
end
