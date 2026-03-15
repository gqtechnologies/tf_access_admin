class Admin::ErrorsController < AdminController
  def not_found
    render inertia: "admin/errors/not_found"
  end
end
