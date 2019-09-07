require "test_helper"

class AirlineTest < ActiveSupport::TestCase
  
  def setup
    @flyer = users(:sampleuser)
  end

  def test_find_by_param_with_id_returns_results
    assert_equal Airline.find_by_param(@flyer, @flyer, 1), [airlines(:airlineAA)]
    assert_equal Airline.find_by_param(@flyer, @flyer, "1"), [airlines(:airlineAA)]
  end

  def test_find_by_param_with_slug_returns_results
    assert_equal Airline.find_by_param(@flyer, @flyer, "american-airlines"), [airlines(:airlineAA)]
  end

  def test_find_by_param_with_iata_returns_results
    assert_equal Airline.find_by_param(@flyer, @flyer, "AA"), [airlines(:airlineAA)]
  end

  def test_find_by_param_with_icao_returns_results
    assert_equal Airline.find_by_param(@flyer, @flyer, "AAL"), [airlines(:airlineAA)]
  end

  def test_find_by_param_filters_when_not_logged_in
    assert_equal Airline.find_by_param(@flyer, nil, "OH"), [airlines(:airlineComair)]
  end

  def test_find_by_param_returns_blank_array_with_no_results_found
    assert_equal Airline.find_by_param(@flyer, @flyer, "XX"), []
  end

end
