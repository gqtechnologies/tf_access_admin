class Admin::UsersController < AdminController

    def new
        render inertia: "admin/users/new", props: {
            roles: AvailableRoles::TENANT
        }
    end

    def create
        render inertia: "admin/users/create"
    end
end
