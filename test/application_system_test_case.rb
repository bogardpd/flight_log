require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # driven_by :selenium, using: :headless_chrome, screen_size: [820, 1200]
  driven_by :selenium, using: :chrome, screen_size: [820, 1200]
  
end
