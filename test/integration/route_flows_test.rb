require "test_helper"

class RouteFlowsTest < ActionDispatch::IntegrationTest

  def setup
    @visible_route = [airports(:airport_visible_1), airports(:airport_visible_2)]
    @hidden_route = [airports(:airport_hidden_1), airports(:airport_hidden_2)]

    @extension_types = {
      'geojson' => "application/geo+json",
      'gpx'     => "application/gpx+xml",
      'graphml' => "application/xml",
      'kml'     => "application/vnd.google-earth.kml+xml",
    }
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Edit Route                                #
  ##############################################################################

  test "can see edit route when logged in" do
    route = routes(:route_dfw_ord)
    log_in_as(users(:user_one))
    get(edit_route_path(route.airport1, route.airport2))
    assert_response(:success)

    # assert_select("h1", ["Edit", route.airport1.iata_code, Route::ARROW_TWO_WAY_PLAINTEXT, route.airport2.iata_code].join(" "))
    assert_select("h1", "Edit #{Route.airport_string(route.airport1, route.airport2, sort: false)}")
    assert_select("input#route_distance_mi[value=?]", route.distance_mi.to_s)
    assert_select("input[type=submit][value=?]", "Update Route")
  end

  test "cannot see edit route when not logged in" do
    route = routes(:route_dfw_ord)
    get(edit_route_path(route.airport1, route.airport2))
    assert_redirected_to(login_path)
  end

  test "can update route when logged in" do
    log_in_as(users(:user_one))
    route = routes(:route_dfw_ord)
    distance_update = 1234
    assert_difference("Route.count", 0) do
      patch(route_path(route), params: {route: {distance_mi: distance_update}})
      assert_equal(distance_update, Route.find(route.id).distance_mi)
    end
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Index Routes                              #
  ##############################################################################

  test "can see index routes when logged in" do
    stub_aero_api4_get_timeout

    routes = Route.flight_table_data(logged_in_flights)

    log_in_as(users(:user_one))
    get(routes_path)
    assert_response(:success)

    assert_select("h1", "Routes")

    assert_select("table#route-count-table") do
      check_flight_row(routes, @visible_route, "This view shall show routes with visible flights")
      check_flight_row(routes, @hidden_route, "This view shall show routes with only hidden flights when logged in")
      assert_select("td#route-count-total[data-total=?]", routes.size.to_s, {}, "Ranked tables shall have a total row with a correct total")
    end
  end

  test "can see index routes when not logged in" do
    stub_aero_api4_get_timeout

    get(routes_path)
    assert_response(:success)
    verify_absence_of_hidden_data
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Show Route                                #
  # Tests for trip_and_section_table partial                                   #
  ##############################################################################

  test "redirect show unused or hidden routes when appropriate" do
    verify_show_unused_or_hidden_redirects(
      show_hidden_path: show_route_path(*@hidden_route.pluck(:slug)),
      redirect_path:    routes_path
    )
  end

  test "can see show route when not logged in" do
    route = routes(:route_visible)
    get(show_route_path(route.airport1.slug, route.airport2.slug))
    assert_response(:success)
    verify_absence_of_hidden_data
    verify_absence_of_admin_actions(edit_route_path(route.airport1_id, route.airport2_id))

    assert_select(".single-flight-map")
    assert_select(".flights-map", {count: 2})
    assert_select("#flight-table")
    assert_select(".distance-mi")
    assert_select("#trip-and-section-table")
    assert_select("#airline-count-table")
    assert_select("#operator-count-table")
    assert_select("#aircraft-family-count-table")
    assert_select("#travel-class-count-table")
  end

  test "can see show route when logged in" do
    route = routes(:route_visible)
    log_in_as(users(:user_one))
    get(show_route_path(route.airport1.slug, route.airport2.slug))
    assert_response(:success)
    verify_presence_of_admin_actions(edit_route_path(route.airport1_id, route.airport2_id))
  end

  test "can see show route alternate map formats" do
    route = routes(:route_visible)
    %w(gpx kml geojson).each do |extension|
      %w(route_map sections_map trips_map).each do |map_id|
        get(show_route_path(route.airport1.slug, route.airport2.slug, map_id: map_id, extension: extension))
        assert_response(:success)
        assert_equal(@extension_types[extension], response.media_type)
      end
    end
  end

  ##############################################################################
  # Tests to ensure visitors can't create or update routes                     #
  ##############################################################################

  test "visitor cannot create or update routes" do
    # post(routes_path)
    # assert_redirected_to(root_path)
    # Route does not have a new or create action

    put(route_path(routes(:route_visible)))
    assert_redirected_to(login_path)

    # Route does not have a destroy action
  end

  private

  # Runs tests on a row in a route count table
  def check_flight_row(flight_table_data, route_to_check, error_message)
    route_data = flight_table_data.find{|r| r[:route].sort == route_to_check.sort}
    sorted_slugs = route_to_check.pluck(:slug).sort
    assert_select("tr#route-count-row-#{sorted_slugs.join("-to-")}", {}, error_message) do
      assert_select("a[href=?]", show_route_path(*sorted_slugs))
      assert_select("text.graph-distance[data-distance-mi=?]", route_data[:distance_mi].to_s, {}, "Graph bar shall have the correct distance")
      assert_select("text.graph-value[data-value=?]", route_data[:flight_count].to_s, {}, "Graph bar shall have the correct flight count")
    end
  end

end
