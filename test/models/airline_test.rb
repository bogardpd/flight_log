require "test_helper"

class AirlineTest < ActiveSupport::TestCase
  
  def test_airline_has_any_airline_operator_codeshare_flights_with_airline
    assert airlines(:airlineAA).has_any_airline_operator_codeshare_flights?
  end

  def test_airline_has_any_airline_operator_codeshare_flights_with_operator
    assert airlines(:airlineOperatorOnly).has_any_airline_operator_codeshare_flights?
  end

  def test_airline_has_any_airline_operator_codeshare_flights_with_codeshare
    assert airlines(:airlineCodeshareOnly).has_any_airline_operator_codeshare_flights?
  end

  def test_airline_has_any_airline_operator_codeshare_flights_with_no_flights
    assert_not airlines(:airlineNoFlights).has_any_airline_operator_codeshare_flights?
  end

end
