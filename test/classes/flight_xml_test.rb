require "test_helper"

class FlightXMLTest < ActiveSupport::TestCase
  
  def setup
    stub_flight_xml_get_wsdl
  end
  
  def test_airport_coordinates
    icao_code = airports(:airport_with_no_coordinates).icao_code
    coordinates = [43.677223, -79.630556]
    
    stub_flight_xml_post_airport_info(airports(:airport_with_no_coordinates).icao_code, {latitude: coordinates[0], longitude: coordinates[1]})

    assert_equal(coordinates, FlightXML.airport_coordinates(icao_code))

  end
  
  
  
end
