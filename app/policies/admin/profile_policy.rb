class Admin::ProfilePolicy < ApplicationPolicy
    def edit?
        same_user?
    end

    def update?
        same_user?
    end
end
