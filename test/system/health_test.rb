require "application_system_test_case"

class HealthTest < ApplicationSystemTestCase
  test "health check is reachable" do
    visit rails_health_check_url
    assert page.has_css?("body")
  end
end
