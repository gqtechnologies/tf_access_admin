class Admin::ProfileController < AdminController

    before_action :get_user, only: [:edit, :update]
    after_action :handle_avatar, only: [:update]
    
    def edit
        authorize @user, :edit?, policy_class: Admin::ProfilePolicy

        render inertia: "admin/profile/edit", 
        props: {
            user: Admin::UserSerializer.new(@user).as_json,
            languages: Languages::ALL,
        }
    end

    def update
        authorize @user, :update?, policy_class: Admin::ProfilePolicy
        user_update_params = user_params
        if user_update_params[:password].blank?
            user_update_params.delete(:password)
            user_update_params.delete(:password_confirmation)
        end

        if @user.update(user_update_params)
            redirect_to edit_admin_profile_path(@user)
        else
            redirect_to edit_admin_profile_path(@user), inertia: { errors: @user.errors }
        end
    end

    private

    def get_user
        @user = User.find_by(id: params[:id])
        if @user.blank?
            redirect_to admin_home_index_path, inertia: { errors: [I18n.t("frontend.admin.users.not_found")]  }
            return
        end
    end

    def user_params
        params.require(:user).permit(:name, :email, :dni, :password, :password_confirmation, :language)
    end

    def handle_avatar
        if @user.avatar.attached? && params[:user][:avatar].blank?
            @user.avatar.purge
        elsif params[:user][:avatar].present?
            @user.avatar.attach(params[:user][:avatar])
        end
    end
end
