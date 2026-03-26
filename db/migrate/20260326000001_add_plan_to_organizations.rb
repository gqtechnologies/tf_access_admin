class AddPlanToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :plan, :string, null: false, default: "free"
    add_index :organizations, :plan
  end
end
