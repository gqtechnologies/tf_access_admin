class CreateOrganizations < ActiveRecord::Migration[8.1]
  def change
    create_table :organizations, id: :uuid do |t|
      t.string :name
      t.string :subdomain

      t.timestamps
    end
    add_index :organizations, :subdomain, unique: true
  end
end
