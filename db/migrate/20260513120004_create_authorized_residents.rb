# frozen_string_literal: true

class CreateAuthorizedResidents < ActiveRecord::Migration[8.1]
  def change
    create_table :authorized_residents, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :unit, null: false, foreign_key: true, type: :uuid
      t.references :person, null: false, foreign_key: { to_table: :people }, type: :uuid
      t.references :authorized_by_person, foreign_key: { to_table: :people }, type: :uuid, null: true, index: false
      t.references :authorized_by_user, foreign_key: { to_table: :users }, type: :uuid, null: true, index: false
      t.string :relationship_type, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at
      t.string :status, null: false, default: "pending"
      t.boolean :can_authorize_visits, null: false, default: false
      t.boolean :can_withdraw_parcels, null: false, default: false
      t.boolean :can_reserve_common_areas, null: false, default: false
      t.text :notes
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :authorized_residents, %i[organization_id unit_id status],
              name: "index_authorized_residents_on_org_unit_status"
    add_index :authorized_residents, %i[organization_id person_id status],
              name: "index_authorized_residents_on_org_person_status"
    add_index :authorized_residents, %i[organization_id authorized_by_person_id],
              name: "index_authorized_residents_on_org_authorized_by_person_id"
    add_index :authorized_residents, :metadata, using: :gin
  end
end
