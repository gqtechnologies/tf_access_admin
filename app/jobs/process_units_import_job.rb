# frozen_string_literal: true

class ProcessUnitsImportJob < ApplicationJob
  queue_as :default

  def perform(bulk_import_id)
    bulk_import = BulkImport.find(bulk_import_id)
    BulkImportServices::ProcessUnitsImport.call(bulk_import:)
  end
end
