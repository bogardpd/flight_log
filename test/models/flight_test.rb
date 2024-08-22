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
  
end
