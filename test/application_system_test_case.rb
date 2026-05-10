require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Rack is enough for non-JS smoke tests and runs in CI without Chrome.
  # Switch to :selenium + :headless_chrome when you need a real browser.
  driven_by :rack_test
end
