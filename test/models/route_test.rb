require "test_helper"

class RouteTest < ActiveSupport::TestCase
  
  def test_distance_by_airport_with_known_route
    airport1 = airports(:airportDFW)
    airport2 = airports(:airportORD)
    assert_equal(Route.distance_by_airport(airport1, airport2), 801)
  end

  def test_distance_by_airport_with_unknown_route
    airport1 = airports(:airportSEA)
    airport2 = airports(:airportYVR)
    assert_equal(Route.distance_by_airport(airport1, airport2), 126)
  end

  def test_distance_by_coordinates
    coord1 = [47.4498889,-122.3117778]
    coord2 = [49.193889,-123.184444]
    assert_equal(Route.distance_by_coordinates(coord1, coord2), 126)
  end

end