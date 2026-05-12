# frozen_string_literal: true

class RemoveUserIdFromUnitOccupancies < ActiveRecord::Migration[8.1]
  def up
    return unless column_exists?(:unit_occupancies, :user_id)

    remove_reference :unit_occupancies, :user, type: :uuid, foreign_key: true
  end

  def down
    return if column_exists?(:unit_occupancies, :user_id)

    add_reference :unit_occupancies, :user, foreign_key: true, type: :uuid, null: true
  end
end
