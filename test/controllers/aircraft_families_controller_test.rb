require "test_helper"

class AircraftFamiliesControllerTest < ActionDispatch::IntegrationTest
  
  def test_index_aircraft_families_success
    get aircraft_families_path
    assert_response :success
  end
  
  def test_show_aircraft_family_success
    aircraft_family = aircraft_families(:aircraft_737)
    get aircraft_family_path(aircraft_family)
    assert_response :success
  end
  
  def test_show_aircraft_type_success
    aircraft_type = aircraft_families(:aircraft_737_800)
    get aircraft_family_path(aircraft_type)
    assert_response :success
  end
  
end