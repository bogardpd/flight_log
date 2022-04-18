require "application_system_test_case"

class AirportsTest < ApplicationSystemTestCase
  # All tests to ensure visitors can't view hidden, view empty, create, update,
  # or destroy airports are located in INTEGRATION tests.

  def setup
    stub_aws_head_images
    stub_gcmap_get_map
  end

  test "creating, updating, and destroying an airport" do
    airport = {
      iata_code:   "HEL",
      icao_code:   "EFHK",
      city:        "Helsinki",
      city_update: "Helsinki (Vantaa)",
      country:     "Finland",
      slug:        "HEL",
      latitude:    60.31722,
      longitude:   24.96333
    }

    stub_aero_api4_get_airports_id(airports(:airport_with_no_coordinates).icao_code, {})
    stub_aero_api4_get_airports_id(airport[:icao_code], {
      "latitude" => airport[:latitude],
      "longitude" => airport[:longitude],
      })

    system_log_in_as(users(:user_one))

    # Create airport:
    assert_difference("Airport.count", 1) do
      visit(airports_path)
      click_on("Add New Airport")

      fill_in("IATA Code",   with: airport[:iata_code])
      fill_in("ICAO Code",   with: airport[:icao_code])
      fill_in("City",        with: airport[:city])
      fill_in("Country",     with: airport[:country])
      fill_in("Unique Slug", with: airport[:slug])
      click_on("Add Airport")

      new_airport = Airport.find_by(slug: airport[:slug])
      assert_equal(airport[:latitude], new_airport.latitude)
      assert_equal(airport[:longitude], new_airport.longitude)
    end

    # Update airport:
    assert_no_difference("Airport.count") do
      visit(airport_path(airport[:slug]))
      click_on("Edit Airport")

      fill_in("City", with: airport[:city_update])
      click_on("Update Airport")

      assert_equal(airport[:city_update], Airport.find_by(slug: airport[:slug]).city)
    end

    # Destroy airport:
    assert_difference("Airport.count", -1) do
      visit(airport_path(airport[:slug]))
      accept_confirm do
        click_on("Delete Airport")
      end

      # Give the delete enough time to go through:
      find("#menu")
    end

  end
end
