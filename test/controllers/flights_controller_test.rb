require 'test_helper'

class FlightsControllerTest < ActionDispatch::IntegrationTest
  
  def test_index_flights_success
    get flights_path
    assert_response :success
  end

  
#  def test_show_flight_success
#    flight = flights(:flight1)
#    get flight_path(flight)
#    assert_response :success
#  end
  
end