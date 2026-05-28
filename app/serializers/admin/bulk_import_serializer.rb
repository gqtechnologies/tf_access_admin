# frozen_string_literal: true

class Admin::BulkImportSerializer < ActiveModel::Serializer
  attributes :id,
             :status,
             :import_type,
             :original_filename,
             :content_type,
             :file_size,
             :metadata,
             :residential_property_id,
             :property_section_id,
             :created_at,
             :total_rows,
             :valid_rows,
             :warning_rows,
             :error_rows,
             :skipped_rows,
             :imported_rows,
             :failed_rows

  def metadata
    object.metadata.deep_stringify_keys
  end
end
