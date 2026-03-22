class Admin::OrganizationsController < AdminController
    before_action :set_filters, only: [:index]
    before_action :set_organization, only: [:show, :edit, :update]
    before_action :validate_organization_subdomain, only: [:update]
    after_action :handle_cover, only: [:update]
    after_action :handle_logo, only: [:update]

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

    def show
        authorize @organization
        render inertia: "admin/organizations/show", props: {
            organization: Admin::OrganizationSerializer.new(@organization).as_json
        }, status: :ok
    end

    def edit
        authorize @organization

        render inertia: "admin/organizations/edit", props: {
            organization: Admin::OrganizationSerializer.new(@organization).as_json
        }, status: :ok
    end

    def update
        authorize @organization
        @organization.update(organization_params)

        if @validation_errors ||  !@organization.update(organization_params)
            redirect_to edit_admin_organization_path(@organization), inertia: { errors: @organization.errors }

        else
            redirect_to edit_admin_organization_path(@organization)
        end
    end

    private

    def validate_organization_subdomain
        organization_subdomain = params[:organization][:subdomain]
        if organization_subdomain.blank?
            @organization.errors.add(:subdomain, "admin.organizations.validations.subdomain_blank")
            return false
        end
        if organization_subdomain.length != 6 || !organization_subdomain.match(/^[a-z-][a-z0-9-]*$/)
            @organization.errors.add(:subdomain, "admin.organizations.validations.subdomain_invalid")
            return false
        end
        if Organization.exists?(subdomain: organization_subdomain) && organization_subdomain != @organization.subdomain
            @organization.errors.add(:subdomain, "admin.organizations.validations.subdomain_exists")
            return false
        end
        return true
    end

    def set_organization
        @organization = Organization.find_by(id: params[:id])
        if @organization.blank?
            if current_user.super_admin?
                redirect_to admin_organizations_path, inertia: { errors: [I18n.t("frontend.admin.organizations.not_found")]  }
                return
            else
                redirect_to admin_home_index_path, inertia: { errors: [I18n.t("frontend.admin.organizations.not_found")]  }
                return
            end
        end
    end

    def organization_params
        params.require(:organization).permit(:name, :subdomain)
    end

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

    def handle_cover
        org = params[:organization]
        return if org.blank?

        if ActiveModel::Type::Boolean.new.cast(org[:remove_cover])
            @organization.cover.purge
        elsif org[:cover].present?
            @organization.cover.attach(org[:cover])
        end
    end

    def handle_logo
        org = params[:organization]
        return if org.blank?

        if ActiveModel::Type::Boolean.new.cast(org[:remove_logo])
            @organization.logo.purge
        elsif org[:logo].present?
            @organization.logo.attach(org[:logo])
        end
    end
end
