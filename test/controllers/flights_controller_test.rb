require 'test_helper'

class FlightsControllerTest < ActionDispatch::IntegrationTest
  
  def test_index_flights_success
    get flights_path
    assert_response :success
  end

  # def test_show_flight_success
  #   flight = flights(:flight1)
  #   get flight_path(flight)
  #   assert_response :success
  # end

  def test_index_tails_success
    get tails_path
    assert_response :success
  end
  
  # def test_show_tails_success
  #   get show_tail_path("N12345")
  #   assert_response :success
  # end
  
end