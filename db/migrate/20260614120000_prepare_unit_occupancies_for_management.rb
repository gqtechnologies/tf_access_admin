# frozen_string_literal: true

class PrepareUnitOccupanciesForManagement < ActiveRecord::Migration[8.1]
  def up
    add_column :unit_occupancies, :deleted_at, :datetime
    add_index :unit_occupancies, :deleted_at

    migrate_legacy_occupancy_types!

    add_index :unit_occupancies,
              %i[organization_id unit_id person_id],
              unique: true,
              where: "deleted_at IS NULL",
              name: "index_unit_occupancies_on_org_unit_person_not_deleted"
  end

  def down
    remove_index :unit_occupancies,
                 name: "index_unit_occupancies_on_org_unit_person_not_deleted",
                 if_exists: true
    remove_index :unit_occupancies, :deleted_at, if_exists: true
    remove_column :unit_occupancies, :deleted_at, if_exists: true
  end

  def migrate_legacy_occupancy_types!
    execute <<~SQL.squish
      UPDATE unit_occupancies
      SET occupancy_type = 'owner_resident'
      WHERE occupancy_type = 'owner'
    SQL

    execute <<~SQL.squish
      UPDATE unit_occupancies
      SET occupancy_type = 'family_member'
      WHERE occupancy_type = 'family'
    SQL
  end
end
