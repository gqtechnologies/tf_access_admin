class Admin::HomeController < AdminController
  def index
    render inertia: "admin/home/index", props: {}
  end
end
