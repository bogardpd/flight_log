require "application_system_test_case"

class RoutesTest < ApplicationSystemTestCase
  # All tests to ensure visitors can't view hidden routes or update routes are
  # located in INTEGRATION tests.

  def setup
    stub_gcmap_get_map
    @airports_with_no_route_distance = [airports(:airport_dfw), airports(:airport_sea)]
  end

  # There is no form to create a new route; instead, new routes are created by
  # {Route.distance_by_airport} (tested in /test/models/route_test.rb), or if a
  # user tries to edit a route that's not already in the database.
  test "creating a route by editing route with no distance" do
    
    # We don't look up distance in FlightXML, and the airports already have coordinates:
    stub_aero_api4_get_timeout
    # stub_flight_xml_post_timeout

    system_log_in_as(users(:user_one))

    assert_difference("Route.count", 1) do
      visit(routes_path)
      click_on(Route.airport_string(*@airports_with_no_route_distance))
    end

  end

  # Update route:
  test "updating a route" do
    stub_aero_api4_get_timeout
    
    route = routes(:route_visible)
    distance_update = 1234

    system_log_in_as(users(:user_one))

    assert_no_difference("Route.count") do
      visit(show_route_path(route.airport1.slug, route.airport2.slug))
      click_on("Edit Route")

      fill_in("Distance", with: distance_update)
      click_on("Update Route")

      assert_equal(distance_update, Route.find(route.id).distance_mi)
    end
  end

  # This application has no destroy route functionality.

end
