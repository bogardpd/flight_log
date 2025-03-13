require "application_system_test_case"

class ApisTest < ApplicationSystemTestCase
  # Test viewing the API index page.
  test "viewing the API index page" do
    visit api_url
    assert_selector "h1", text: "API"
  end

  # Test that recent_flights returns a JSON response.
  test "recent_flights returns JSON" do
    visit api_recent_flights_url
    result = JSON.parse(page.text)
    assert_equal true, result["success"]
  end

end
