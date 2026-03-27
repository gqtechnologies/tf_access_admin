class Admin::UsersController < AdminController
    before_action :set_user, only: [:create]
    before_action :get_user, only: [:edit, :update, :destroy]
    before_action :validate_role, only: [:create, :update]

    def index
        authorize User
        @q = policy_scope(User).ransack(params[:q])
        users = @q.result(distinct: true)
                    .order(created_at: :desc)
                    .page(@filters[:page])
                    .per(@filters[:per_page])
        
        pagination = pagination_info(users)
        render inertia: "admin/users/index", props: {
            users: users.map { |u| Admin::UserSerializer.new(u).as_json },
            pagination: pagination
        }, status: :ok
    end

    def new
        authorize User
        render inertia: "admin/users/new", props: {
            roles: AvailableRoles::TENANT,
            languages: Languages::ALL
        }
    end

    def create
        authorize User

        if @validation_errors || !@user.save
            redirect_to new_admin_user_path, inertia: { errors: @user.errors }
        else
            redirect_to admin_users_path
        end
    end

    def edit
        authorize @user
        
        user_json = Admin::UserSerializer.new(@user).as_json

        user_json[:role] = user_json[:tenant_role]
        render inertia: "admin/users/edit", props: {
            user: user_json,
            roles: AvailableRoles::TENANT,
            languages: Languages::ALL,
        }
    end

    def update
        authorize @user
        user_update_params = user_params
        if user_update_params[:password].blank?
            user_update_params.delete(:password)
            user_update_params.delete(:password_confirmation)
        end

        if @validation_errors ||  !@user.update(user_update_params)
            redirect_to edit_admin_user_path(@user), inertia: { errors: @user.errors }

        else
            redirect_to edit_admin_user_path(@user)
        end
    end

    def destroy
        authorize @user
        @user.destroy
        redirect_to admin_users_path
    end

    private

    def set_user
        @user = User.new(user_params)
        @validation_errors = false
    end

    def get_user
        @user = User.find(params[:id])
        if @user.blank?
            redirect_to admin_users_path, inertia: { errors: [I18n.t("frontend.admin.users.not_found")]  }
            return
        end
    end

    def validate_role
        role = params[:user][:role]
        if role.present?
            if AvailableRoles::TENANT_ROLE_PRIORITY.include?(role)
                @user.set_tenant_role(role)
            else
                @user.errors.add(:role, "admin.users.validations.role_invalid")
                @validation_errors = true
            end
        end
    end

    def user_params
        params.require(:user).permit(:name, :email, :dni, :password, :password_confirmation, :language)
    end

    def pagination_info(users)
        {
            current_page: users.current_page,
            per_page: @filters[:per_page],
            total_pages: users.total_pages,
            total_count: users.total_count,
        }
    end
end
