require "test_helper"

class AirportTest < ActiveSupport::TestCase
  
  def test_direct_flight_count
    flights = Flight.find([1,2])
    airport = Airport.where(iata_code: "DFW").first
    direct_flight_airports = Airport.direct_flight_count(flights, airport)
    assert direct_flight_airports[0][:iata_code] == "ORD"
    assert direct_flight_airports[0][:total_flights] == 1
    assert direct_flight_airports[1][:iata_code] == "SEA"
    assert direct_flight_airports[1][:total_flights] == 1
  end

  def test_remote_airport
    local_id = 1
    remote_id = 2
    airport = Airport.find(local_id)
    assert airport.remote_airport(local_id,remote_id) == remote_id
    assert airport.remote_airport(remote_id,local_id) == remote_id
    assert airport.remote_airport(local_id,local_id) == local_id
    assert_nil airport.remote_airport(remote_id,remote_id)
  end

end