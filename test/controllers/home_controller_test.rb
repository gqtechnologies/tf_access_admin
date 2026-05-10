require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get home_url(host: "example.com")
    assert_response :success
  end
end
