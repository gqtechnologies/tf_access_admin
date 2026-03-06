# frozen_string_literal: true

class AddOrganizationToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :organization, type: :uuid, foreign_key: true, index: true
  end
end
