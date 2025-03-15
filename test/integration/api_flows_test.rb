require "test_helper"

class TripFlowsTest < ActionDispatch::IntegrationTest

  def setup
  end

  test "should get index" do
    get api_url
    assert_response :success
  end
  
  test "should return 403 for recent_flights without api key" do
    get api_recent_flights_url
    assert_response :forbidden
  end

  test "should return 403 for recent_flights with invalid api key" do
    get api_recent_flights_url, headers: {'api-key' => "badkey"}
    assert_response :forbidden
  end
  
  test "should get recent_flights" do 
    get api_recent_flights_url, headers: {'api-key' => users(:user_one).api_key}
    assert_response :success
    assert_equal "application/json", @response.media_type
    assert_equal JSON.generate({success: true}), @response.body
  end

end
