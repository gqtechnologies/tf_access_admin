# frozen_string_literal: true

class AddDeletedAtToUnitOwnerships < ActiveRecord::Migration[8.1]
  def change
    add_column :unit_ownerships, :deleted_at, :datetime
    add_index :unit_ownerships, :deleted_at
  end
end
