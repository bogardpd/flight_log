require "test_helper"

class ApiFlowsTest < ActionDispatch::IntegrationTest

  def setup
  end

  test "should get index if logged in" do
    log_in_as(users(:user_one))
    get api_url
    assert_response :success
  end

  test "should not get index if logged in" do
    get api_url
    assert_redirected_to(login_path)
  end

  # annual_flight_summary

  test "should return 403 for annual_flight_summary with empty or bad api key" do
    check_empty_or_bad_api_key(api_annual_flight_summary_url)
  end

  test "should get annual_flight_summary" do
    get api_annual_flight_summary_url, headers: {'api-key' => users(:user_one).api_key}
    assert_response :success
    assert_equal "application/json", @response.media_type
    assert_equal JSON.generate(users(:user_one).annual_flight_summary(users(:user_one))), @response.body
  end

  # recent_flights

  test "should return 403 for recent_flights with empty or bad api key" do
    check_empty_or_bad_api_key(api_recent_flights_url)
  end

  test "should get recent_flights" do
    expected_result = [
      {
        departure_utc: flights(:flight_recent_1).departure_utc.iso8601,
        fh_id: flights(:flight_recent_1).id,
        fa_flight_id: flights(:flight_recent_1).fa_flight_id,
      },
      {
        departure_utc: flights(:flight_recent_2).departure_utc.iso8601,
        fh_id: flights(:flight_recent_2).id,
        fa_flight_id: flights(:flight_recent_2).fa_flight_id,
      },
    ]
    get api_recent_flights_url, headers: {'api-key' => users(:user_one).api_key}
    assert_response :success
    assert_equal "application/json", @response.media_type
    assert_equal JSON.generate(expected_result), @response.body
  end

  private

  def check_empty_or_bad_api_key(path)
    get path
    assert_response :forbidden
    assert_equal JSON.generate(ApiController::AUTHENTICATION_ERROR), @response.body

    get path, headers: {'api-key' => "badkey"}
    assert_response :forbidden
    assert_equal JSON.generate(ApiController::AUTHENTICATION_ERROR), @response.body
  end

end
