# frozen_string_literal: true

class CreateLeaseContracts < ActiveRecord::Migration[8.1]
  def change
    create_table :lease_contracts, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :unit, null: false, foreign_key: true, type: :uuid
      t.references :lessee_person, null: false, foreign_key: { to_table: :people }, type: :uuid
      t.references :lessor_person, foreign_key: { to_table: :people }, type: :uuid, null: true
      t.date :starts_at, null: false
      t.date :ends_at
      t.string :status, null: false, default: "draft"
      t.boolean :can_authorize_visits, null: false, default: true
      t.boolean :can_withdraw_parcels, null: false, default: true
      t.boolean :can_reserve_common_areas, null: false, default: true
      t.references :created_by, foreign_key: { to_table: :users }, type: :uuid, null: true
      t.references :terminated_by, foreign_key: { to_table: :users }, type: :uuid, null: true
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :lease_contracts, %i[organization_id unit_id starts_at ends_at],
              name: "index_lease_contracts_on_org_unit_date_range"
    add_index :lease_contracts, %i[organization_id lessee_person_id status],
              name: "index_lease_contracts_on_org_lessee_person_status"
    add_index :lease_contracts, %i[organization_id unit_id],
              unique: true,
              where: "status = 'active'",
              name: "index_lease_contracts_on_org_unit_unique_when_active"
    add_index :lease_contracts, :metadata, using: :gin
  end
end
