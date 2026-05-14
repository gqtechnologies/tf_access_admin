# frozen_string_literal: true

class CreateCommonAreaReservations < ActiveRecord::Migration[8.1]
  def up
    enable_extension "btree_gist" unless extension_enabled?("btree_gist")

    create_table :common_area_reservations, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :common_area, null: false, foreign_key: true, type: :uuid
      t.references :residential_property, null: false, foreign_key: true, type: :uuid
      t.references :unit, null: false, foreign_key: true, type: :uuid
      t.references :requested_by_person, null: false, foreign_key: { to_table: :people }, type: :uuid
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :status, null: false, default: "pending"
      t.references :approved_by_person, foreign_key: { to_table: :people }, type: :uuid
      t.datetime :approved_at
      t.text :rejection_reason
      t.integer :guest_count, default: 0
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :common_area_reservations, %i[organization_id common_area_id starts_at ends_at],
              name: "index_common_area_reservations_on_org_area_time_range"
    add_index :common_area_reservations, %i[organization_id unit_id status]
    add_index :common_area_reservations, %i[organization_id requested_by_person_id status],
              name: "index_common_area_reservations_on_org_requester_status"
    add_index :common_area_reservations, %i[organization_id approved_by_person_id],
              name: "index_common_area_reservations_on_org_approved_by_person"
    add_index :common_area_reservations, %i[organization_id status]
    add_index :common_area_reservations, :metadata, using: :gin

    add_check_constraint :common_area_reservations, "ends_at > starts_at",
                         name: "common_area_reservations_time_range_valid"

    # tsrange matches `datetime` columns (timestamp without time zone); tstzrange would not be immutable here.
    execute <<~SQL.squish
      ALTER TABLE common_area_reservations
      ADD CONSTRAINT common_area_reservations_no_overlap
      EXCLUDE USING gist (
        organization_id WITH =,
        common_area_id WITH =,
        tsrange(starts_at, ends_at, '[)') WITH &&
      )
      WHERE (status IN ('pending', 'approved'))
    SQL
  end

  def down
    execute <<~SQL.squish
      ALTER TABLE common_area_reservations
      DROP CONSTRAINT IF EXISTS common_area_reservations_no_overlap
    SQL

    drop_table :common_area_reservations
  end
end
