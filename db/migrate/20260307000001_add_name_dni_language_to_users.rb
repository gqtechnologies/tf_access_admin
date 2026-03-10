# frozen_string_literal: true

class AddNameDniLanguageToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :name, :string
    add_column :users, :dni, :string
    add_column :users, :language, :string
  end
end
