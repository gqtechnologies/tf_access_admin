class ChangeRolesResourceIdToString < ActiveRecord::Migration[8.1]
  def up
    change_column :roles, :resource_id, :string
  end

  def down
    change_column :roles, :resource_id, :bigint
  end
end