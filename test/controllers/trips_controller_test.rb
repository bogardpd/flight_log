require 'test_helper'

class TripsControllerTest < ActionDispatch::IntegrationTest
  
  def test_index_trips_success
    get trips_path
    assert_response :success
  end
  
  def test_show_trip_success
    trip = trips(:tripChicagoSeattle)
    get trip_path(trip)
    assert_response :success
  end
  
  def test_show_trip_section_success
    trip = trips(:tripChicagoSeattle)
    get show_section_path(trip: trip, section: 1)
    assert_response :success
  end
  
end