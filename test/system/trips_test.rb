require "application_system_test_case"

class TripsTest < ApplicationSystemTestCase
  # All tests to ensure visitors can't view hidden, view empty, create, update,
  # or destroy trips are located in INTEGRATION tests.

  test "creating, updating, and destroying a trip" do
    trip = {
      name: "Vacation",
      purpose: "Personal",
      comment: "This was a great vacation!"
    }
    
    system_log_in_as(users(:user_one))

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
