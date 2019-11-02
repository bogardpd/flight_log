require "test_helper"

class RoutesControllerTest < ActionDispatch::IntegrationTest
  
  def test_show_route_success
    get show_route_path(airport1: airports(:airport_dfw).slug, airport2: airports(:airport_ord).slug)
    assert_response :success
  end
  
end