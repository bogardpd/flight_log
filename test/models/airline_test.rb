require "test_helper"

class AirlineTest < ActiveSupport::TestCase
  
  def setup
    @flyer = users(:sampleuser)
  end

  def test_find_by_param_with_id_returns_results
    assert_equal Airline.find_by_param(:airline, 1, @flyer, @flyer), [airlines(:airlineAA)]
    assert_equal Airline.find_by_param(:airline, "1", @flyer, @flyer), [airlines(:airlineAA)]
  end

  def test_find_by_param_only_looks_for_numeric_ids
    assert_equal Airline.find_by_param(:airline, "1I", @flyer, @flyer), [airlines(:airlineNetJets)] 
  end

  def test_find_by_param_with_slug_returns_results
    assert_equal Airline.find_by_param(:airline, "American-Airlines", @flyer, @flyer), [airlines(:airlineAA)]
  end

  def test_find_by_param_with_iata_returns_results
    assert_equal Airline.find_by_param(:airline, "AA", @flyer, @flyer), [airlines(:airlineAA)]
  end

  def test_find_by_param_with_icao_returns_results
    assert_equal Airline.find_by_param(:airline, "AAL", @flyer, @flyer), [airlines(:airlineAA)]
  end

  def test_find_by_param_finds_multiple_results
    assert_equal Airline.find_by_param(:operator, "OH", @flyer, @flyer), [airlines(:airlineComair), airlines(:airlinePSA)]
  end

  def test_find_by_param_filters_when_not_logged_in
    assert_equal Airline.find_by_param(:operator, "OH", @flyer, nil), [airlines(:airlineComair)]
  end

  def test_find_by_param_returns_blank_array_with_no_results_found
    assert_equal Airline.find_by_param(:airline, "XX", @flyer, @flyer), []
  end

end
