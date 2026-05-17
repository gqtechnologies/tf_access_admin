# frozen_string_literal: true

# Builds Inertia pagination props for Kaminari collections.
# Requires @filters (see AdminController#set_filters) on index actions.
module PaginationProps
  extend ActiveSupport::Concern

  private

  def pagination_info(collection)
    {
      current_page: collection.current_page,
      per_page: @filters[:per_page],
      total_pages: collection.total_pages,
      total_count: collection.total_count
    }
  end
end
