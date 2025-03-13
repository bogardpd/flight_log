require "test_helper"

class ApiControllerTest < ActionDispatch::IntegrationTest
  test "should get recent_flights" do
    get api_recent_flights_url
    assert_response :success
  end
end
