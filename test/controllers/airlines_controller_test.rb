require "test_helper"

class AirlinesControllerTest < ActionDispatch::IntegrationTest
  
  def setup
    @user = users(:user_one)
    @airline = airlines(:airline_american)
    @operator = airlines(:airline_expressjet)
  end

  def test_index_airlines_success
    get airlines_path
    assert_response :success
  end
  
  def test_show_airline_success
    get airline_path(@airline.slug)
    assert_response :success
  end
  
  def test_show_operator_success
    get show_operator_path(@operator.slug)
    assert_response :success
  end
  
  def test_show_fleet_number_success
    get show_fleet_number_path(operator: @operator.slug, fleet_number: "123")
    assert_response :success
  end

  # def test_destroy_airline_success
  #   log_in_as(@user) # Need to log in or else destroy will never be called. However, with rails 5 we can't do this as a controller test anymore. Switch to integration test.
  #   @airline = airlines(:airline_no_flights)
  #   assert_difference("Airline.count", -1) do
  #     delete delete_airline_path(airline)
  #   end
  # end

  # def test_airline_should_not_destroy_with_flights
  #   airline = airlines(:airline_american)
  #   assert_difference("Airline.count", 0) do
  #     delete airline_url(airline)
  #   end
  #   #assert_redirected_to airline_path(airline.slug)
  # end

  # def test_airline_should_not_destroy_with_operated_flights
  #   operator = airlines(:airline_operator_only)
  #   assert_difference("Airline.count", 0) do
  #     delete airline_url(operator)
  #   end
  #   assert_redirected_to airlines_path
  # end
  
end