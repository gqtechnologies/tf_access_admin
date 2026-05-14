# frozen_string_literal: true

# Recreates the `audits` table that the `audited` gem installer created with
# integer IDs. The whole project uses UUID primary keys, so audits.user_id /
# auditable_id / associated_id must be UUID. Also adds `organization_id` to
# isolate audits per tenant.
#
# Safe to run in pre-production: any existing rows in `audits` are discarded
# because the integer IDs they hold cannot reference our UUID-primary-keyed
# records anyway.
class FixAuditsForUuidAndTenant < ActiveRecord::Migration[8.1]
  def up
    drop_table :audits, if_exists: true

    create_table :audits, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid    :auditable_id
      t.string  :auditable_type
      t.uuid    :associated_id
      t.string  :associated_type
      t.uuid    :user_id
      t.string  :user_type
      t.string  :username
      t.string  :action
      t.text    :audited_changes
      t.integer :version, default: 0
      t.string  :comment
      t.string  :remote_address
      t.string  :request_uuid
      t.uuid    :organization_id
      t.datetime :created_at
    end

    add_index :audits, [ :auditable_type, :auditable_id, :version ], name: "auditable_index"
    add_index :audits, [ :associated_type, :associated_id ],          name: "associated_index"
    add_index :audits, [ :user_id, :user_type ],                       name: "user_index"
    add_index :audits, :request_uuid
    add_index :audits, :created_at
    add_index :audits, :organization_id
    add_index :audits,
              [ :organization_id, :auditable_type, :auditable_id, :created_at ],
              name: "index_audits_on_org_auditable_created_at"

    add_foreign_key :audits, :organizations, column: :organization_id
  end

  def down
    drop_table :audits, if_exists: true

    create_table :audits, force: true do |t|
      t.column :auditable_id,    :integer
      t.column :auditable_type,  :string
      t.column :associated_id,   :integer
      t.column :associated_type, :string
      t.column :user_id,         :integer
      t.column :user_type,       :string
      t.column :username,        :string
      t.column :action,          :string
      t.column :audited_changes, :text
      t.column :version,         :integer, default: 0
      t.column :comment,         :string
      t.column :remote_address,  :string
      t.column :request_uuid,    :string
      t.column :created_at,      :datetime
    end

    add_index :audits, [ :auditable_type, :auditable_id, :version ], name: "auditable_index"
    add_index :audits, [ :associated_type, :associated_id ],          name: "associated_index"
    add_index :audits, [ :user_id, :user_type ],                       name: "user_index"
    add_index :audits, :request_uuid
    add_index :audits, :created_at
  end
end
