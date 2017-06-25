require "test_helper"

class AirlinesControllerTest < ActionDispatch::IntegrationTest
  
  def test_index_airlines_success
    get airlines_path
    assert_response :success
  end
  
  def test_show_airline_success
    get airline_path("AA")
    assert_response :success
  end
  
  def test_show_operator_success
    get show_operator_path("EV")
    assert_response :success
  end
  
  # def test_show_fleet_number_success
  #   get show_fleet_number_path(operator: "EV", fleet_number: "123")
  #   assert_response :success
  # end
  
end