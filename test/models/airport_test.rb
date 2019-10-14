require "test_helper"

class AirportTest < ActiveSupport::TestCase
  
  def test_direct_flight_count
    flights = Flight.find([flights(:flight_ord_dfw).id, flights(:flight_dfw_sea).id])
    airport = Airport.where(iata_code: "DFW").first
    direct_flight_airports = Airport.direct_flight_count(flights, airport)
    assert direct_flight_airports[0][:iata_code] == "ORD"
    assert direct_flight_airports[0][:total_flights] == 1
    assert direct_flight_airports[1][:iata_code] == "SEA"
    assert direct_flight_airports[1][:total_flights] == 1
  end

  def test_remote_airport
    local_airport = airports(:airport_dfw)
    remote_airport = airports(:airport_ord)

    assert_equal(remote_airport.id, local_airport.remote_airport(local_airport.id,remote_airport.id))
    assert_equal(remote_airport.id, local_airport.remote_airport(remote_airport.id,local_airport.id))
    assert_equal(local_airport.id, local_airport.remote_airport(local_airport.id,local_airport.id))
    assert_nil(local_airport.remote_airport(remote_airport.id,remote_airport.id))
  end

end