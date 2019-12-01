require "application_system_test_case"

class AircraftFamiliesTest < ApplicationSystemTestCase
  # All tests to ensure visitors can't view hidden, view empty, create, update,
  # or destroy aircraft are located in INTEGRATION tests.

  def setup
    stub_system_common_requests
  end

  test "creating, updating, and destroying an aircraft family and type" do
    family = {
      manufacturer:       "Embraer",
      family_name:        "ERJ-145 Family",
      slug:               "Embraer-ERJ-145-Family",
      category:           "Regional Jet"
    }
    type = {
      family_name:        "ERJ-145",
      family_name_update: "ERJ-145 A",
      iata_aircraft_code: "ER4",
      icao_aircraft_code: "E145",
      slug:               "Embraer-ERJ-145"
    }
    system_log_in_as(users(:user_one))

    # Create aircraft family:
    assert_difference("AircraftFamily.count", 1) do
      visit(aircraft_families_path)
      click_on("Add New Aircraft Family")

      fill_in("Manufacturer",         with: family[:manufacturer])
      fill_in("Aircraft Family Name", with: family[:family_name])
      fill_in("Unique Slug",          with: family[:slug])
      select(family[:category], from: "aircraft_family_category")
      click_on("Add Aircraft Family")
    end

    # Create subtype:
    assert_difference("AircraftFamily.count", 1) do
      visit(aircraft_family_path(family[:slug]))
      click_on("Add Type")

      fill_in("Aircraft Type Name", with: type[:family_name])
      fill_in("IATA Aircraft Code", with: type[:iata_aircraft_code])
      fill_in("ICAO Aircraft Code", with: type[:icao_aircraft_code])
      fill_in("Unique Slug",        with: type[:slug])
      click_on("Add Aircraft Type")
    end

    # Update subtype:
    assert_no_difference("AircraftFamily.count") do
      visit(aircraft_family_path(type[:slug]))
      click_on("Edit Aircraft")

      fill_in("Aircraft Type Name", with: type[:family_name_update])
      click_on("Update Aircraft Family")

      assert_equal(type[:family_name_update], AircraftFamily.find_by(slug: type[:slug]).family_name)
    end

    # Destroy subtype and family:
    assert_difference("AircraftFamily.count", -2) do
      # Destroy subtype:
      visit(aircraft_family_path(type[:slug]))
      accept_confirm do
        click_on("Delete Aircraft")
      end

      # Destroy family:
      visit(aircraft_family_path(family[:slug]))
      accept_confirm do
        click_on("Delete Aircraft")
      end
      
      # Give the delete enough time to go through:
      visit(aircraft_families_path)
    end

  end
  
end
