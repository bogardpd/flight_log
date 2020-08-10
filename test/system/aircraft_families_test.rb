require "application_system_test_case"

class AircraftFamiliesTest < ApplicationSystemTestCase
  # All tests to ensure visitors can't view hidden, view empty, create, update,
  # or destroy aircraft are located in INTEGRATION tests.

  def setup
    stub_aws_head_images
    stub_flight_xml_get_wsdl
    stub_flight_xml_post_timeout
    stub_gcmap_get_map
  end

  test "creating, updating, and destroying an aircraft family and type" do

    family = {
      manufacturer:       "Embraer",
      name:        "ERJ-145 Family",
      slug:               "Embraer-ERJ-145-Family",
      category:           "Regional Jet"
    }
    type = {
      name:        "ERJ-145",
      name_update: "ERJ-145 A",
      iata_code: "ER4",
      icao_code: "E145",
      slug:               "Embraer-ERJ-145"
    }
    system_log_in_as(users(:user_one))

    # Create aircraft family:
    assert_difference("AircraftFamily.count", 1) do
      visit(aircraft_families_path)
      click_on("Add New Aircraft Family")

      fill_in("Manufacturer",         with: family[:manufacturer])
      fill_in("Family Name", with: family[:name])
      fill_in("Unique Slug",          with: family[:slug])
      select(family[:category], from: "aircraft_family_category")
      click_on("Add Aircraft Family")
    end

    # Create subtype:
    assert_difference("AircraftFamily.count", 1) do
      visit(aircraft_family_path(family[:slug]))
      click_on("Add Type")

      fill_in("Type Name", with: type[:name])
      fill_in("IATA Code", with: type[:iata_code])
      fill_in("ICAO Code", with: type[:icao_code])
      fill_in("Unique Slug",        with: type[:slug])
      click_on("Add Aircraft Type")
    end

    # Update subtype:
    assert_no_difference("AircraftFamily.count") do
      visit(aircraft_family_path(type[:slug]))
      click_on("Edit Aircraft")

      fill_in("Type Name", with: type[:name_update])
      click_on("Update Aircraft Family")

      assert_equal(type[:name_update], AircraftFamily.find_by(slug: type[:slug]).name)
    end

    # Destroy subtype and family:
    assert_difference("AircraftFamily.count", -2) do
      # Destroy subtype:
      visit(aircraft_family_path(type[:slug]))
      accept_confirm do
        click_on("Delete Aircraft")
      end

      # Give the subtype delete enough time to go through:
      find("#menu")

      # Destroy family:
      visit(aircraft_family_path(family[:slug]))
      accept_confirm do
        click_on("Delete Aircraft")
      end
      
      # Give the delete enough time to go through:
      find("#menu")
    end

  end
  
end
