require "test_helper"

class AeroAPI4Test < ActiveSupport::TestCase
  
  def setup
    flight = flights(:flight_ord_dfw)
    ident = "#{flight.airline.icao_code}#{flight.flight_number}"
    @samples = {
      ident: ident,
      fa_flight_id: "#{ident}-#{flight.departure_utc.to_i}-airline-0001",
      origin_airport_icao: flight.origin_airport.icao_code,
      destination_airport_icao: flight.destination_airport.icao_code,
      aircraft_family_icao: flight.aircraft_family.icao_code,
      departure_utc: flight.departure_utc,
    }
  end

  def test_api_request
    stub_aero_api4_get_flights_ident(@samples[:ident], {
      "fa_flight_id" => @samples[:fa_flight_id]
    })
    result = AeroAPI4.api_request("/flights/#{@samples[:ident]}")
    assert_equal(@samples[:fa_flight_id], result[:flights][0][:fa_flight_id])
  end

  def test_airport_coordinates
    icao_code = airports(:airport_with_no_coordinates).icao_code
    coordinates = [43.677223, -79.630556]
    
    stub_aero_api4_get_airports_id(icao_code, {
      "latitude"  => coordinates[0],
      "longitude" => coordinates[1],
    })

    assert_equal(coordinates, AeroAPI4.airport_coordinates(icao_code))
  end

  def test_flight_lookup
    stub_aero_api4_get_flights_ident(@samples[:ident], {
      "fa_flight_id" => @samples[:fa_flight_id]
    })
    result = AeroAPI4.flight_lookup(@samples[:ident])
    assert_equal(@samples[:fa_flight_id], result[0][:fa_flight_id])
  end

  def test_form_values
    stub_aero_api4_get_flights_ident(@samples[:fa_flight_id], {
      "origin"      => {"code" => @samples[:origin_airport_icao]},
      "destination" => {"code" => @samples[:destination_airport_icao]},
      "aircraft_type" => @samples[:aircraft_family_icao],
      "scheduled_out" => @samples[:departure_utc],
    })
    result = AeroAPI4.form_values(@samples[:fa_flight_id])
    assert_equal(@samples[:origin_airport_icao], result[:origin_airport_icao])
    assert_equal(@samples[:destination_airport_icao], result[:destination_airport_icao])
    assert_equal(@samples[:aircraft_family_icao], result[:aircraft_family_icao])
    assert_equal(@samples[:departure_utc], result[:departure_utc])
  end

  def test_get_flight_id
    stub_aero_api4_get_flights_ident(@samples[:ident], {
      "fa_flight_id"  => @samples[:fa_flight_id],
      "scheduled_out" => @samples[:departure_utc]
    })
    result = AeroAPI4.get_flight_id(@samples[:ident], @samples[:departure_utc])
    assert_equal(@samples[:fa_flight_id], result)

    stub_aero_api4_get_flights_ident(@samples[:ident], {
      "fa_flight_id"  => @samples[:fa_flight_id],
      "scheduled_out" => @samples[:departure_utc] + 10.minutes
    })
    result = AeroAPI4.get_flight_id(@samples[:ident], @samples[:departure_utc])
    assert_nil(result)
  end

  def test_departure_times
    time_keys = [:scheduled_out, :scheduled_off, :estimated_out, :estimated_off, :actual_out, :actual_off]
    
    # Test that hashes with no times return nil
    empty = time_keys.map {|t| [t, nil]}.to_h
    assert_nil(AeroAPI4.departure_time(empty))
    
    # Test that hashes with times return the first non-nil time.
    time_vals = time_keys.each_with_index.map {|t, i| [t, (Time.now + (i*5).minutes).iso8601]}.to_h
    assert_equal(Time.parse(time_vals[time_keys[0]]), AeroAPI4.departure_time(time_vals))

    # Make the first time nil, second time should be returned.
    time_vals[time_keys[0]] = nil
    assert_equal(Time.parse(time_vals[time_keys[1]]), AeroAPI4.departure_time(time_vals))
  end

  def test_arrival_times
    time_keys = [:scheduled_in, :scheduled_on, :estimated_in, :estimated_on, :actual_in, :actual_on]
    
    # Test that hashes with no times return nil
    empty = time_keys.map {|t| [t, nil]}.to_h
    assert_nil(AeroAPI4.arrival_time(empty))
    
    # Test that hashes with times return the first non-nil time.
    time_vals = time_keys.each_with_index.map {|t, i| [t, (Time.now + (i*5).minutes).iso8601]}.to_h
    assert_equal(Time.parse(time_vals[time_keys[0]]), AeroAPI4.arrival_time(time_vals))

    # Make the first time nil, second time should be returned.
    time_vals[time_keys[0]] = nil
    assert_equal(Time.parse(time_vals[time_keys[1]]), AeroAPI4.arrival_time(time_vals))
  end
  
end
