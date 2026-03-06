# frozen_string_literal: true

class AddOrganizationToRoles < ActiveRecord::Migration[8.1]
  def change
    add_reference :roles, :organization, type: :uuid, foreign_key: true, index: true
  end
end
