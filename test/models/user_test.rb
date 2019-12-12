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
  
end
