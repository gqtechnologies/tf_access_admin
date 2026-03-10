class Admin::UsersController < AdminController
    before_action :set_user, only: [:create]
    before_action :validate_role, only: [:create]

    def index
        render inertia: "admin/users/index", props: {
            users: User.all
        }, status: :ok
    end

    def new
        render inertia: "admin/users/new", props: {
            roles: AvailableRoles::TENANT,
            languages: Languages::ALL
        }
    end

    def create
        if @validation_errors || !@user.save
            render inertia: "admin/users/new",
                props: {
                    roles: AvailableRoles::TENANT,
                    languages: Languages::ALL,
                    errors: @user.errors.messages.to_h,
                },
                status: :unprocessable_entity
        else
            redirect_to admin_users_path
        end
    end

    private

    def set_user
        @user = User.new(user_params)
        @validation_errors = false
    end

    def validate_role
        role = params[:user][:role]
        if role.present?
            if AvailableRoles::ALL.include?(role)
                @user.add_role(role, @user.organization)
            else
                @user.errors.add(:role, "users.validations.role_invalid")
                @validation_errors = true
            end
        end
    end

    def user_params
        params.require(:user).permit(:name, :email, :dni, :password, :password_confirmation, :language)
    end
end
