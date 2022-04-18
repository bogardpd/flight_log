require "test_helper"

class TripTest < ActiveSupport::TestCase
  
  def setup
    @trip = trips(:trip_layover_ratios)
    @delta = 0.001
  end
  
  def test_layover_ratio_for_section_with_no_flights
    assert_nil @trip.layover_ratio(6) # no flights
  end

  def test_layover_ratio_for_section_with_one_flight
    ratio = @trip.layover_ratio(1) # ORD-DFW
    assert_not_nil ratio
    assert_in_delta ratio, 1.000, @delta
  end

  def test_layover_ratio_for_section_with_multiple_flights
    ratio = @trip.layover_ratio(2) # DFW-ORD-SEA
    assert_not_nil ratio
    assert_in_delta ratio, 1.518, @delta
  end

  def test_layover_ratio_for_section_with_zero_and_nonzero_distance_flights
    ratio = @trip.layover_ratio(3) # ORD-ORD-YVR
    assert_not_nil ratio
    assert_in_delta ratio, 1.000, @delta
  end

  def test_layover_ratio_for_section_with_only_zero_distance_flight
    assert_nil @trip.layover_ratio(4) # YVR-YVR
  end

  def test_layover_ratio_for_section_with_unknown_distance_flight
    stub_aero_api_get_timeout
    assert_nil @trip.layover_ratio(5) # ORD-DFW-YYZ, DFW-YYZ unknown
  end

  def test_matching_trips_and_sections
    flights = Flight.find([flights(:flight_ord_dfw).id, flights(:flight_dfw_sea).id])
    matching = Trip.matching_trips_and_sections(flights)
    assert matching.dig(0, :trip_id) == flights[0].trip_id
    assert matching.dig(0, :sections, 0, :trip_section) == 1
  end
  
end
