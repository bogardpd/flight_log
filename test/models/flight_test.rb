require 'test_helper'

class FlightTest < ActiveSupport::TestCase
  
  def setup
  end

  def test_total_distance_with_known_routes
    flights = Flight.where(id: [flights(:flight_ord_dfw).id,flights(:flight_sea_ord).id])
    assert_equal(2517, flights.total_distance)
  end

  def test_total_distance_with_an_unknown_route_without_coordinates_allowing_unknown_distances
    flights = Flight.where(id: flights(:flight_layover_ratio_unknown_distance_f2).id)
    assert_equal(0, flights.total_distance(true))
  end

  def test_total_distance_with_an_unknown_route_without_coordinates
    flights = Flight.where(id: flights(:flight_layover_ratio_unknown_distance_f2).id)
    assert_nil(flights.total_distance(false))
  end

  def test_fa_flight_ids_array_with_null_id
    flight = flights(:flight_fa_flight_id_null)
    assert_equal([], flight.fa_flight_ids_array)
  end

  def test_fa_flight_ids_array_with_single_id
    flight = flights(:flight_fa_flight_id_single)
    assert_equal(["AAL602-1234567890-airline-0000"], flight.fa_flight_ids_array)
  end

  def test_fa_flight_ids_array_with_multiple_ids
    flight = flights(:flight_fa_flight_id_multiple)
    assert_equal(["AAL603-1234567890-airline-0000", "AAL603-1234567890-airline-0001"], flight.fa_flight_ids_array)
  end
  
end
