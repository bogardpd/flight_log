require "application_system_test_case"

class TripsTest < ApplicationSystemTestCase
  # All tests to ensure visitors can't view hidden, view empty, create, update,
  # or destroy trips are located in INTEGRATION tests.

  def setup
    stub_system_common_requests
  end

  test "creating, updating, and destroying a trip" do
    trip = {
      name: "Vacation",
      purpose: "Personal",
      comment: "This was a great vacation!"
    }
    user = users(:user_one)
    system_log_in_as(user)

    # Create trip:
    assert_difference("Trip.count", 1) do
      visit(trips_path)
      click_on("Add New Trip")

      fill_in("Trip Name", with: trip[:name])
      select(trip[:purpose], from: "trip_purpose")
      check("trip_hidden")
      fill_in("Comment", with: trip[:comment])
      click_on("Add Trip")

      assert_equal(true, Trip.last.hidden)
      assert_equal(user, Trip.last.user)
    end

    # Update trip:
    assert_no_difference("Trip.count") do
      visit(trip_path(Trip.last))
      click_on("Edit Trip")

      uncheck("trip_hidden")
      click_on("Update Trip")

      assert_equal(false, Trip.last.hidden)
    end
    
    # Destroy trip:
    assert_difference("Trip.count", -1) do
      visit(trip_path(Trip.last))
      accept_confirm do
        click_on("Delete Trip")
      end

      # Give the delete enough time to go through:
      visit(trips_path)
    end

  end
end
