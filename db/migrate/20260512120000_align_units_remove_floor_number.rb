# frozen_string_literal: true

# Mantiene la tabla `units` alineada con create_units cuando la BD quedó con
# columnas de una versión anterior del esquema (p. ej. floor_number).
class AlignUnitsRemoveFloorNumber < ActiveRecord::Migration[8.1]
  def up
    return unless table_exists?(:units)

    remove_column :units, :floor_number if column_exists?(:units, :floor_number)
    add_column :units, :display_name, :string unless column_exists?(:units, :display_name)
  end

  def down
    return unless table_exists?(:units)

    remove_column :units, :display_name, if_exists: true
    add_column :units, :floor_number, :integer unless column_exists?(:units, :floor_number)
  end
end
