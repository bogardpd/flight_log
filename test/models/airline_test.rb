require "test_helper"

class AirlineTest < ActiveSupport::TestCase
  
  def test_find_by_param_with_id_returns_results
    assert_equal Airline.find_by_param(1), [airlines(:airlineAA)]
    assert_equal Airline.find_by_param("1"), [airlines(:airlineAA)]
  end

  def test_find_by_param_with_slug_returns_results
    assert_equal Airline.find_by_param("american-airlines"), [airlines(:airlineAA)]
  end

  def test_find_by_param_with_iata_returns_results
    assert_equal Airline.find_by_param("AA"), [airlines(:airlineAA)]
  end

  def test_find_by_param_with_icao_returns_results
    assert_equal Airline.find_by_param("AAL"), [airlines(:airlineAA)]
  end

  def test_find_by_param_returns_multiple_results
    assert_equal Airline.find_by_param("OH"), [airlines(:airlineComair), airlines(:airlinePSA)]
  end

  def test_find_by_param_returns_blank_array_with_no_results_found
    assert_equal Airline.find_by_param("XX"), []
  end

end
