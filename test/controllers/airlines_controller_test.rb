require "test_helper"

class AirlinesControllerTest < ActionDispatch::IntegrationTest
  
  def setup
    @user = users(:sampleuser)
  end

  def test_index_airlines_success
    get airlines_path
    assert_response :success
  end
  
  def test_show_airline_success
    get airline_path("American-Airlines")
    assert_response :success
  end
  
  def test_show_operator_success
    get show_operator_path("ExpressJet")
    assert_response :success
  end
  
  def test_show_fleet_number_success
    get show_fleet_number_path(operator: "ExpressJet", fleet_number: "123")
    assert_response :success
  end

  # def test_destroy_airline_success
  #   log_in_as(@user) # Need to log in or else destroy will never be called. However, with rails 5 we can't do this as a controller test anymore. Switch to integration test.
  #   @airline = airlines(:airlineNoFlights)
  #   assert_difference("Airline.count", -1) do
  #     delete delete_airline_path(airline)
  #   end
  # end

  # def test_airline_should_not_destroy_with_flights
  #   airline = airlines(:airlineAA)
  #   assert_difference("Airline.count", 0) do
  #     delete airline_url(airline)
  #   end
  #   #assert_redirected_to airline_path(airline.slug)
  # end

  # def test_airline_should_not_destroy_with_operated_flights
  #   operator = airlines(:airlineOperatorOnly)
  #   assert_difference("Airline.count", 0) do
  #     delete airline_url(operator)
  #   end
  #   assert_redirected_to airlines_path
  # end
  
end