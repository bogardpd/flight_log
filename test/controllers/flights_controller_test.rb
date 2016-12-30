require 'test_helper'

class FlightsControllerTest < ActionDispatch::IntegrationTest
  
  def setup
    @trip = trips(:trip1)
  end
  
  def test_new_redirects_if_not_logged_in
    get new_flight_path(trip_id: @trip)
    assert_redirected_to root_path
  end
  
end