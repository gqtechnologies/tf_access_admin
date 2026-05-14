# frozen_string_literal: true

class CreateCommonAreaReservationStatusHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :common_area_reservation_status_histories, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :common_area_reservation, null: false, foreign_key: true, type: :uuid
      t.string :from_status
      t.string :to_status, null: false
      t.references :changed_by_person, foreign_key: { to_table: :people }, type: :uuid
      t.text :reason
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :common_area_reservation_status_histories,
              %i[organization_id common_area_reservation_id created_at],
              name: "idx_c_area_res_status_histories_on_org_res_created"
    add_index :common_area_reservation_status_histories, %i[organization_id changed_by_person_id],
              name: "idx_c_area_res_status_histories_on_org_changed_by"
    add_index :common_area_reservation_status_histories, :metadata, using: :gin
  end
end
