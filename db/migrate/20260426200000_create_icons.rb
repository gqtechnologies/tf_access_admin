# frozen_string_literal: true

class CreateIcons < ActiveRecord::Migration[8.1]
  def change
    create_table :icons, id: :uuid do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :icons, :name, unique: true
  end
end
