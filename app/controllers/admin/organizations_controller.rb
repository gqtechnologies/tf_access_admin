class Admin::OrganizationsController < AdminController
    before_action :set_filters, only: [:index]


    def index
        authorize Organization
        @q = policy_scope(Organization).ransack(params[:q])
        organizations = @q.result(distinct: true)
                    .order(created_at: :desc)
                    .page(@filters[:page])
                    .per(@filters[:per_page])
        
        pagination = pagination_info(organizations)
        render inertia: "admin/organizations/index", props: {
            organizations: organizations.map { |o| Admin::OrganizationSerializer.new(o).as_json },
            pagination: pagination
        }, status: :ok
    end
    private

    def set_filters
        @filters = {
            page: params[:page] || 1,
            per_page: params[:per_page] || 10,
        }
    end

    def pagination_info(organizations)
        {
            current_page: organizations.current_page,
            per_page: @filters[:per_page],
            total_pages: organizations.total_pages,
            total_count: organizations.total_count,
        }
    end
end
