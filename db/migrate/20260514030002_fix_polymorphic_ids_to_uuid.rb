# frozen_string_literal: true

# Polymorphic *_id columns were created as `bigint`, but every target table in
# the project uses UUID primary keys. The values stored today cannot resolve
# to a real record, so any existing rows are discarded (pre-production).
#
# Affected tables and columns:
#   - notifications.notifiable_id      (bigint, NOT NULL)
#   - documents.documentable_id        (bigint, NOT NULL)
#   - announcement_targets.target_id   (bigint, NOT NULL)
#   - unit_occupancies.source_id       (bigint, nullable)
class FixPolymorphicIdsToUuid < ActiveRecord::Migration[8.1]
  def up
    say_with_time "Truncating tables with broken polymorphic ids" do
      execute "TRUNCATE TABLE notifications RESTART IDENTITY CASCADE"
      execute "TRUNCATE TABLE documents RESTART IDENTITY CASCADE"
      execute "TRUNCATE TABLE announcement_targets RESTART IDENTITY CASCADE"
      execute "TRUNCATE TABLE unit_occupancies RESTART IDENTITY CASCADE"
    end

    fix_polymorphic_id(
      table: :notifications,
      type_column: :notifiable_type,
      id_column: :notifiable_id,
      composite_index_name: "index_notifications_on_org_notifiable",
      null: false
    )

    fix_polymorphic_id(
      table: :documents,
      type_column: :documentable_type,
      id_column: :documentable_id,
      composite_index_name: "index_documents_on_org_documentable",
      null: false
    )

    fix_polymorphic_id(
      table: :announcement_targets,
      type_column: :target_type,
      id_column: :target_id,
      composite_index_name: "index_announcement_targets_on_org_target",
      null: false
    )

    fix_polymorphic_id(
      table: :unit_occupancies,
      type_column: :source_type,
      id_column: :source_id,
      composite_index_name: "index_unit_occupancies_on_org_source",
      null: true
    )
  end

  def down
    revert_polymorphic_id(
      table: :notifications,
      type_column: :notifiable_type,
      id_column: :notifiable_id,
      composite_index_name: "index_notifications_on_org_notifiable",
      null: false
    )

    revert_polymorphic_id(
      table: :documents,
      type_column: :documentable_type,
      id_column: :documentable_id,
      composite_index_name: "index_documents_on_org_documentable",
      null: false
    )

    revert_polymorphic_id(
      table: :announcement_targets,
      type_column: :target_type,
      id_column: :target_id,
      composite_index_name: "index_announcement_targets_on_org_target",
      null: false
    )

    revert_polymorphic_id(
      table: :unit_occupancies,
      type_column: :source_type,
      id_column: :source_id,
      composite_index_name: "index_unit_occupancies_on_org_source",
      null: true
    )
  end

  private

  def fix_polymorphic_id(table:, type_column:, id_column:, composite_index_name:, null:)
    if index_exists?(table, [ :organization_id, type_column, id_column ], name: composite_index_name)
      remove_index table, name: composite_index_name
    end

    remove_column table, id_column
    add_column    table, id_column, :uuid, null: null

    add_index table,
              [ :organization_id, type_column, id_column ],
              name: composite_index_name
  end

  def revert_polymorphic_id(table:, type_column:, id_column:, composite_index_name:, null:)
    if index_exists?(table, [ :organization_id, type_column, id_column ], name: composite_index_name)
      remove_index table, name: composite_index_name
    end

    remove_column table, id_column
    add_column    table, id_column, :bigint, null: null

    add_index table,
              [ :organization_id, type_column, id_column ],
              name: composite_index_name
  end
end
