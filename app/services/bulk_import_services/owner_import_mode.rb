# frozen_string_literal: true

module BulkImportServices
  module OwnerImportMode
    DEFAULT = CreateUnitsImport::OWNER_IMPORT_MODES[:ignore]

    def self.resolve(mode, default: DEFAULT)
      return mode if CreateUnitsImport::OWNER_IMPORT_MODES.value?(mode)

      default
    end

    def ignore_owners?
      owner_import_mode == CreateUnitsImport::OWNER_IMPORT_MODES[:ignore]
    end

    def link_existing_owners?
      owner_import_mode == CreateUnitsImport::OWNER_IMPORT_MODES[:link_existing]
    end

    def create_missing_owners?
      owner_import_mode == CreateUnitsImport::OWNER_IMPORT_MODES[:create_missing]
    end

    def process_owners?
      !ignore_owners?
    end
  end
end
