require "test_helper"

class AircraftFamilyTest < ActiveSupport::TestCase
  
  def setup
    @flyer = users(:sampleuser)
  end

  def test_find_by_param_with_id_returns_results
    assert_equal AircraftFamily.find_by_param(1, @flyer, @flyer), [aircraft_families(:aircraft_737)]
    assert_equal AircraftFamily.find_by_param("1", @flyer, @flyer), [aircraft_families(:aircraft_737)]
  end

  def test_find_by_param_only_looks_for_numeric_ids
    assert_equal AircraftFamily.find_by_param("1-Air", @flyer, @flyer), [aircraft_families(:aircraft_1_Air)] 
  end

  def test_find_by_param_with_slug_returns_results
    assert_equal AircraftFamily.find_by_param("Boeing-737-700", @flyer, @flyer), [aircraft_families(:aircraft_737_700)]
  end

  def test_find_by_param_finds_multiple_results
    assert_equal AircraftFamily.find_by_param("72", @flyer, @flyer), [aircraft_families(:aircraft_id_72), aircraft_families(:aircraft_slug_72)]
  end

  def test_find_by_param_filters_when_not_logged_in
    assert_equal AircraftFamily.find_by_param("Airbus-A380", @flyer, nil), []
  end

  def test_gets_parent_with_no_flights_of_child_with_flights_when_not_logged_in
    assert_equal AircraftFamily.find_by_param("Parent-Child", @flyer, nil), [aircraft_families(:aircraft_with_only_subtype_child)]
    assert_equal AircraftFamily.find_by_param("Parent-Parent", @flyer, nil), [aircraft_families(:aircraft_with_only_subtype_parent)]
  end

  def test_find_by_param_returns_blank_array_with_no_results_found
    assert_equal AircraftFamily.find_by_param("Fake-Airline", @flyer, @flyer), []
  end

end
