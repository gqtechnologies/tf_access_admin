# frozen_string_literal: true

class CreateAccessEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :access_events, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :residential_property, null: false, foreign_key: true, type: :uuid
      t.references :unit, foreign_key: true, type: :uuid
      t.references :visit, foreign_key: true, type: :uuid
      t.references :visit_participant, foreign_key: true, type: :uuid
      t.references :visitor_profile, foreign_key: true, type: :uuid
      t.references :vehicle, foreign_key: true, type: :uuid
      t.references :recorded_by_user, foreign_key: { to_table: :users }, type: :uuid
      t.uuid :staff_shift_id
      t.string :event_type, null: false
      t.datetime :occurred_at, null: false
      t.string :result, null: false, default: "success"
      t.string :source, null: false, default: "web"
      t.inet :ip_address
      t.text :user_agent
      t.text :notes
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :access_events, %i[organization_id residential_property_id occurred_at],
              name: "index_access_events_on_org_property_occurred_at"
    add_index :access_events, %i[organization_id visit_id occurred_at],
              name: "index_access_events_on_org_visit_occurred_at"
    add_index :access_events, %i[organization_id unit_id occurred_at],
              name: "index_access_events_on_org_unit_occurred_at"
    add_index :access_events, %i[organization_id event_type result occurred_at],
              name: "index_access_events_on_org_type_result_occurred_at"
    add_index :access_events, :metadata, using: :gin
  end
end
