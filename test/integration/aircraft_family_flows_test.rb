require "test_helper"

class AircraftFamilyFlowsTest < ActionDispatch::IntegrationTest
  
  ##############################################################################
  # Tests for Spec > Pages (Views) > Add/Edit Aircraft Family/Type             #
  ##############################################################################

  test "can see add aircraft family when logged in" do
    log_in_as(users(:user_one))
    get(new_aircraft_family_path)
    assert_response(:success)

    assert_select("h1", "New Aircraft Family")
    assert_select("form#new_aircraft_family")
    assert_select("input#aircraft_family_family_name")
    assert_select("input#aircraft_family_manufacturer")
    assert_select("select#aircraft_family_category")
  end

  test "can see add aircraft family type when logged in" do
    parent = aircraft_families(:aircraft_737)
    log_in_as(users(:user_one))
    get(new_aircraft_family_path(family_id: parent.id))
    assert_response(:success)

    assert_select("h1", "New #{parent.family_name} Type")
    assert_select("form#new_aircraft_family")
    assert_select("input#aircraft_family_family_name")
    assert_select("input#aircraft_family_manufacturer[value=?]", parent.manufacturer)
    assert_select("input#aircraft_family_iata_aircraft_code")
    assert_select("input#aircraft_family_icao_aircraft_code")
    assert_select("select#aircraft_family_category") do
      assert_select("option[selected=selected][value=?]", parent.category)
    end
    assert_select("input#aircraft_family_parent_id[value=?]", parent.id.to_s)
  end

  test "cannot see add aircraft family when not logged in" do
    get(new_aircraft_family_path)
    assert_redirected_to(root_path)    
  end

  test "cannot see add aircraft family type when not logged in" do
    parent = aircraft_families(:aircraft_737)
    get(new_aircraft_family_path(family_id: parent.id))
    assert_redirected_to(root_path)
  end

end
