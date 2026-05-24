# frozen_string_literal: true

module BulkImportServices
  class CreateUnitsImport
    IMPORT_MODES = {
      create_skip_duplicates: "create_skip_duplicates",
      create_only: "create_only",
      update_only: "update_only"
    }.freeze

    OWNER_IMPORT_MODES = {
      ignore: "ignore",
      link_existing: "link_existing",
      create_missing: "create_missing"
    }.freeze

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(residential_property:, property_section:, created_by:, file:, options: {})
      @residential_property = residential_property
      @property_section = property_section
      @created_by = created_by
      @file = file
      @options = options.stringify_keys
    end

    def call
      bulk_import = BulkImport.new(
        organization: ActsAsTenant.current_tenant,
        created_by: @created_by,
        residential_property: @residential_property,
        property_section: @property_section,
        import_type: BulkImport::IMPORT_TYPES[:units]
      )

      # Inspect the Rack tempfile before attach: Active Storage uploads to disk in after_commit,
      # so blob.open would raise FileNotFoundError on a new, unsaved record.
      inspection = inspect_uploaded_file
      @file.rewind if @file.respond_to?(:rewind)

      bulk_import.file.attach(@file)
      assign_file_metadata!(bulk_import, inspection:)
      bulk_import.save!
      bulk_import.mark_as_uploaded! if bulk_import.may_mark_as_uploaded?

      bulk_import
    end

    private

    def assign_file_metadata!(bulk_import, inspection:)
      blob = bulk_import.file.blob

      bulk_import.original_filename = blob.filename.to_s
      bulk_import.content_type = blob.content_type
      bulk_import.file_size = blob.byte_size
      bulk_import.file_checksum = blob.checksum
      bulk_import.metadata = build_metadata(inspection)
    end

    def inspect_uploaded_file
      BulkImportServices::FileInspector.call(
        file_path: uploaded_file_path,
        filename: @file.original_filename,
        content_type: @file.content_type
      )
    end

    def uploaded_file_path
      if @file.respond_to?(:tempfile)
        @file.tempfile.path
      else
        @file.path
      end
    end

    def build_metadata(inspection)
      BulkImportServices::MetadataBuilder.call(
        inspection: inspection,
        options: persisted_options
      )
    end

    def persisted_options
      defaults = {
        "import_mode" => IMPORT_MODES[:create_skip_duplicates],
        "property_section_id" => @property_section.id,
        "owner_import_mode" => OWNER_IMPORT_MODES[:link_existing]
      }

      defaults.merge(@options.slice("import_mode", "property_section_id", "owner_import_mode"))
    end
  end
end
