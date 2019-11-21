require "test_helper"

class RouteTest < ActiveSupport::TestCase
  
  test "distance_by_airport with known route returns correct distance" do
    route = routes(:route_dfw_ord)
    assert_no_difference("Route.count") do
      distance = Route.distance_by_airport(route.airport1, route.airport2)
      assert_equal(801, distance)
    end
  end

  test "distance_by_airport with unknown route creates a new route and returns correct distance" do
    airports_with_no_route_distance = [airports(:airport_dfw), airports(:airport_sea)]
    assert_difference("Route.count") do
      distance = Route.distance_by_airport(*airports_with_no_route_distance)
      assert_equal(1658, distance)
    end
  end

  def test_distance_by_airport_with_unknown_route_without_coordinates
    airport1 = airports(:airport_sea)
    airport2 = airports(:airport_yyz)
    assert_nil(Route.distance_by_airport(airport1, airport2))
  end

  def test_distance_by_coordinates
    coord1 = [47.4498889,-122.3117778]
    coord2 = [49.193889,-123.184444]
    assert_equal(126, Route.distance_by_coordinates(coord1, coord2))
  end

end