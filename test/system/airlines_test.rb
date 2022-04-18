require "application_system_test_case"

class AirlinesTest < ApplicationSystemTestCase
  # All tests to ensure visitors can't view hidden, view empty, create, update,
  # or destroy airlines are located in INTEGRATION tests.

  def setup
    stub_gcmap_get_map
    stub_aero_api4_get_timeout
  end

  test "creating, updating, and destroying an airline" do
    
    airline = {
      name:         "British Airways",
      name_update:  "BOAC",
      iata_code:    "BA",
      icao_code:    "BAW",
      numeric_code: "125",
      slug:         "British-Airways",
    }

    system_log_in_as(users(:user_one))

    # Create airline:
    assert_difference("Airline.count", 1) do
      visit(airlines_path)
      click_on("Add New Airline")

      fill_in("Name",         with: airline[:name])
      fill_in("IATA Code",    with: airline[:iata_code])
      fill_in("ICAO Code",    with: airline[:icao_code])
      fill_in("Numeric Code", with: airline[:numeric_code])
      fill_in("Unique Slug",  with: airline[:slug])
      click_on("Add Airline")
    end

    # Update airline:
    assert_no_difference("Airline.count") do
      visit(airline_path(airline[:slug]))
      click_on("Edit Airline")

      fill_in("Name", with: airline[:name_update])
      click_on("Update Airline")
      
      assert_equal(airline[:name_update], Airline.find_by(slug: airline[:slug]).name)
    end

    # Destroy airline:
    assert_difference("Airline.count", -1) do
      visit(airline_path(airline[:slug]))
      accept_confirm do
        click_on("Delete Airline")
      end

      # Give the delete enough time to go through:
      find("#menu")
    end

  end
end
