# frozen_string_literal: true

class CreateVisitParticipants < ActiveRecord::Migration[8.1]
  def change
    create_table :visit_participants, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :visit, null: false, foreign_key: true, type: :uuid
      t.references :visitor_profile, foreign_key: true, type: :uuid
      t.references :person, foreign_key: { to_table: :people }, type: :uuid
      t.string :name_snapshot
      t.string :document_snapshot_digest
      t.string :status, null: false, default: "pending"
      t.datetime :checked_in_at
      t.datetime :checked_out_at
      t.references :validated_by, foreign_key: { to_table: :users }, type: :uuid
      t.text :notes
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :visit_participants, %i[organization_id visit_id status]
    add_index :visit_participants, %i[organization_id visitor_profile_id]
    add_index :visit_participants, %i[organization_id person_id]
    add_index :visit_participants, :metadata, using: :gin
  end
end
