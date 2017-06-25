require "test_helper"

class RoutesControllerTest < ActionDispatch::IntegrationTest
  
  def test_index_routes_success
    get routes_path
    assert_response :success
  end
  
  def test_show_route_success
    get route_path("DFW-ORD")
    assert_response :success
  end
  
end