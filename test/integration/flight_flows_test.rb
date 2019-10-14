require "test_helper"

class FlightFlowsTest < ActionDispatch::IntegrationTest
  
  ##############################################################################
  # Tests for Spec > Pages (Views) > Add Flight Menu                           #
  ##############################################################################
  
  test "can see new flight menu when logged in" do
    trip = trips(:trip_hidden)
  end

  test "cannot see new flight menu when not logged in" do

  end

end
