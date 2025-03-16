require "test_helper"

class UserTest < ActiveSupport::TestCase
  
  def setup
    @flyer = users(:user_one)
    @flight_hidden = flights(:flight_hidden)
  end
  
  test "User.flights returns hidden flights for user" do
    flights = @flyer.flights(@flyer)
    assert_includes(flights, @flight_hidden, "Should include hidden flight")
  end

  test "User.flights does not return hidden flights for visitor" do
    flights = @flyer.flights(nil)
    refute_includes(flights, @flight_hidden, "Should not include hidden flight")
  end

  test "User.annual_flight_summary returns correct data" do
    data = @flyer.annual_flight_summary(@flyer)
    assert_equal(1, data[2005][:count][:personal], "Should
      have one personal flight in 2005")
    assert_equal(801, data[2005][:distance_mi][:personal], "Should have 801 miles (ORD-DFW) in 2005")
  end
  
end
