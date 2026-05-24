# frozen_string_literal: true

class UpdateUnitStatusValues < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      TRUNCATE TABLE units CASCADE
    SQL

    change_column_default :units, :status, from: "active", to: "available"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
