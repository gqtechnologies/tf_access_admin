class HomeController < AdminController
  def index
    render inertia: "home/index", props: {}
  end
end
