# frozen_string_literal: true

class CreateVehicles < ActiveRecord::Migration[8.1]
  def change
    create_table :vehicles, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :person, foreign_key: { to_table: :people }, type: :uuid
      t.references :unit, foreign_key: true, type: :uuid
      t.text :plate_number_ciphertext
      t.string :plate_number_digest
      t.string :brand
      t.string :model
      t.string :color
      t.string :vehicle_type
      t.string :status, null: false, default: "active"
      t.datetime :authorized_from
      t.datetime :authorized_until
      t.jsonb :metadata, null: false, default: {}
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
