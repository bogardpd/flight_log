require "test_helper"

class FlightXMLTest < ActiveSupport::TestCase
  
  def setup
    
  end
  
  def test_savon_client_fails_gracefully
    WebMock.stub_request(:get, "https://flightxml.flightaware.com/soap/FlightXML2/wsdl").
      to_timeout
    
    icao_code = "KORD"
    assert_nil(FlightXML.airport_coordinates(icao_code))
  end

  def test_airport_coordinates
    icao_code = airports(:airport_with_no_coordinates).icao_code
    coordinates = [43.677223, -79.630556]
    
    stub_flight_xml_get_wsdl
    stub_flight_xml_post_airport_info(icao_code, {"latitude": coordinates[0], "longitude": coordinates[1]})

    assert_equal(coordinates, FlightXML.airport_coordinates(icao_code))
  end
  
end
