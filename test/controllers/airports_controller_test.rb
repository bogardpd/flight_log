require "test_helper"

class AirportsControllerTest < ActionDispatch::IntegrationTest
  
  test "show airport success" do
    airport = airports(:airport_sea)
    get airport_path(airport.slug)
    assert_response :success
  end
  
end