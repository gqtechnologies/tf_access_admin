# frozen_string_literal: true

class CreateIncidentStatusHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :incident_status_histories, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :incident, null: false, foreign_key: true, type: :uuid
      t.string :from_status
      t.string :to_status, null: false
      t.references :changed_by_person, foreign_key: { to_table: :people }, type: :uuid
      t.text :reason
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :incident_status_histories, %i[organization_id incident_id created_at],
              name: "index_incident_status_histories_on_org_incident_created_at"
    add_index :incident_status_histories, %i[organization_id changed_by_person_id],
              name: "index_incident_status_histories_on_org_changed_by_person"
    add_index :incident_status_histories, :metadata, using: :gin
  end
end
