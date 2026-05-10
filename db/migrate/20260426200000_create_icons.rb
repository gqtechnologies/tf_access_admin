# frozen_string_literal: true

class CreateIcons < ActiveRecord::Migration[8.1]
  def change
    create_table :icons, id: :uuid, if_not_exists: true do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :icons, :name, unique: true, if_not_exists: true
  end
end
