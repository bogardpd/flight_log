require "test_helper"

class RouteFlowsTest < ActionDispatch::IntegrationTest
  
  ##############################################################################
  # Tests for Spec > Pages (Views) > Edit Route                                #
  ##############################################################################

  test "can see edit route when logged in" do
    route = routes(:route_dfw_ord)
    log_in_as(users(:user_one))
    get(edit_route_path(route.airport1, route.airport2))
    assert_response(:success)

    assert_select("h1", ["Edit", route.airport1.iata_code, Route::ARROW_TWO_WAY_PLAINTEXT, route.airport2.iata_code].join(" "))
    assert_select("input#route_distance_mi[value=?]", route.distance_mi.to_s)
    assert_select("input[type=submit][value=?]", "Submit")
  end

  test "cannot see edit route when not logged in" do
    route = routes(:route_dfw_ord)
    get(edit_route_path(route.airport1, route.airport2))
    assert_redirected_to(root_path)
  end
  
end
