require 'test_helper'

class AirportsControllerTest < ActionDispatch::IntegrationTest
  
  def test_index_airports_success
    get airports_path
    assert_response :success
  end
  
  def test_show_airport_success
    airport = airports(:airportORD)
    get airport_path(airport)
    assert_response :success
  end
  
end