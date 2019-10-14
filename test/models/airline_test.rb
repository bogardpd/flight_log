require "test_helper"

class AirlineTest < ActiveSupport::TestCase
  
  def test_airline_has_any_airline_operator_codeshare_flights_with_airline
    assert airlines(:airline_american).has_any_airline_operator_codeshare_flights?
  end

  def test_airline_has_any_airline_operator_codeshare_flights_with_operator
    assert airlines(:airline_operator_only).has_any_airline_operator_codeshare_flights?
  end

  def test_airline_has_any_airline_operator_codeshare_flights_with_codeshare
    assert airlines(:airline_codeshare_only).has_any_airline_operator_codeshare_flights?
  end

  def test_airline_has_any_airline_operator_codeshare_flights_with_no_flights
    assert_not airlines(:airline_no_flights).has_any_airline_operator_codeshare_flights?
  end

end
