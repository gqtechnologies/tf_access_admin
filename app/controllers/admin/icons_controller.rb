# frozen_string_literal: true

class Admin::IconsController < AdminController
  def index
    authorize Icon

    query = params[:q].to_s.strip
    page = [params[:page].to_i, 1].max
    per_page = params[:per_page].to_i
    per_page = 48 if per_page <= 0
    per_page = [per_page, 100].min

    scope = policy_scope(Icon).ordered
    if query.present?
      like_query = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
      scope = scope.where("name ILIKE ?", like_query)
    end

    icons = scope.page(page).per(per_page)

    render json: {
      icons: icons.map { |icon| { id: icon.id, name: icon.name } },
      meta: {
        current_page: icons.current_page,
        total_pages: icons.total_pages,
        total_count: icons.total_count,
        has_next_page: icons.next_page.present?
      }
    }, status: :ok
  end
end
