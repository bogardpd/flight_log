require "test_helper"

class RoutesControllerTest < ActionDispatch::IntegrationTest
  
  def test_index_routes_success
    get routes_path
    assert_response :success
  end
  
  def test_show_route_success
    get show_route_path(airport1: airports(:airportDFW).slug, airport2: airports(:airportORD).slug)
    assert_response :success
  end
  
end