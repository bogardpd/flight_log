require "test_helper"

class RouteTest < ActiveSupport::TestCase
  
  def test_distance_by_airport_with_known_route
    airport1 = airports(:airportDFW)
    airport2 = airports(:airportORD)
    assert_equal(801, Route.distance_by_airport(airport1, airport2))
  end

  def test_distance_by_airport_with_unknown_route
    airport1 = airports(:airportSEA)
    airport2 = airports(:airportYVR)
    assert_equal(126, Route.distance_by_airport(airport1, airport2))
  end

  def test_distance_by_airport_with_unknown_route_without_coordinates
    airport1 = airports(:airportSEA)
    airport2 = airports(:airportYYZ)
    assert_nil(Route.distance_by_airport(airport1, airport2))
  end

  def test_distance_by_coordinates
    coord1 = [47.4498889,-122.3117778]
    coord2 = [49.193889,-123.184444]
    assert_equal(126, Route.distance_by_coordinates(coord1, coord2))
  end

  def test_total_distance_with_known_routes
    flights = Flight.where(id: [1, 3])
    assert_equal(2517, Route.total_distance(flights))
  end

  def test_total_distance_with_an_unknown_route_with_coordinates
    flights = Flight.where(id: [4])
    assert_equal(1759, Route.total_distance(flights))
  end

  def test_total_distance_with_an_unknown_route_without_coordinates_allowing_unknown_distances
    flights = Flight.where(id: [13])
    assert_equal(0, Route.total_distance(flights, true))
  end

  def test_total_distance_with_an_unknown_route_without_coordinates
    flights = Flight.where(id: [13])
    assert_nil(Route.total_distance(flights, false))
  end

end