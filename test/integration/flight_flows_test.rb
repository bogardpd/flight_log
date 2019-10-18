require "test_helper"

class FlightFlowsTest < ActionDispatch::IntegrationTest
  
  ##############################################################################
  # Tests for Spec > Pages (Views) > Add Flight Menu                           #
  ##############################################################################
  
  test "can see new flight menu when logged in with trip id param" do
    trip = trips(:trip_hidden)
    log_in_as(users(:user_one))
    get(new_flight_menu_path(trip_id: trip.id))
    assert(:success)

    check_new_flight_menu_common(trip)

    assert_select("form#choose-trip") do
      assert_select("select#trip_id") do
        assert_select("option", {count: Trip.count})
        assert_select("option[selected=selected][value=?]", trip.id.to_s)
      end
    end

  end

  test "can see new flight menu when logged in without trip id param" do
    log_in_as(users(:user_one))
    get(new_flight_menu_path)
    assert(:success)

    check_new_flight_menu_common(trips(:trip_hidden_latest))

    assert_select("form#choose-trip") do
      assert_select("select#trip_id") do
        assert_select("option", {count: Trip.count})
        assert_select("option[selected=selected][value=?]", trips(:trip_hidden_latest).id.to_s)
      end
    end
  end

  test "cannot see new flight menu when not logged in with trip id param" do
    trip = trips(:trip_hidden)
    get(new_flight_menu_path(trip_id: trip.id))
    assert_redirected_to(root_path)
  end

  test "cannot see new flight menu when not logged in without trip id param" do
    get(new_flight_menu_path)
    assert_redirected_to(root_path)
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Add/Edit Flight                           #
  ##############################################################################

  test "can see add flight when logged in" do
    trip = trips(:trip_hidden)
    most_recent_flight = Flight.order(:departure_utc).last
    log_in_as(users(:user_one))
    get(new_flight_path(trip_id: trip.id))
    assert_response(:success)

    assert_select("h1", "New Flight")
    assert_select("span#trip-name", trip.name)
    assert_select("input#flight_trip_section")
    assert_select("select#flight_origin_airport_id") do
      assert_select("option", {count: Airport.count + 1})
      assert_select("option[selected=selected][value=?]", most_recent_flight.destination_airport_id.to_s)
    end
    assert_select("select#flight_destination_airport_id") do
      assert_select("option", {count: Airport.count + 1})
    end
    assert_select("select:match('id', ?)", /flight_departure_date_\di/, {count: 3})
    assert_select("select:match('id', ?)", /flight_departure_utc_\di/, {count: 5})
    assert_select("span#utc-time-now", /\d{4,}-\d{1,2}-\d{1,2} \d{2}:\d{2}:\d{2} UTC/)
    assert_select("select#flight_airline_id") do
      assert_select("option", {count: Airline.exclude_only_operators.count + 1})
    end
    assert_select("input#flight_flight_number")
    assert_select("select#flight_codeshare_airline_id") do
      assert_select("option", {count: Airline.exclude_only_operators.count + 1})
    end
    assert_select("input#flight_codeshare_flight_number")
    assert_select("select#flight_aircraft_family_id") do
      assert_select("option", {count: AircraftFamily.count + 1})
    end
    assert_select("input#flight_tail_number")
    assert_select("input#flight_aircraft_name")
    assert_select("select#flight_operator_id") do
      assert_select("option", {count: Airline.count + 1})
    end
    assert_select("input#flight_fleet_number")
    assert_select("select#flight_travel_class") do
      assert_select("option", {count: TravelClass::CLASSES.count + 1})
    end
    assert_select("input#flight_comment")
    assert_select("textarea#flight_boarding_pass_data")
    assert_select("input[type=submit][value=?]", "Add Flight")
  end

  test "cannot see add flight when not logged in" do
    get(new_flight_path)
    assert_redirected_to(root_path)
  end

  test "can see edit flight when logged in" do
    flight = flights(:flight_ord_dfw)
    log_in_as(users(:user_one))
    get(edit_flight_path(flight))
    assert_response(:success)

    assert_select("h1", "Edit Flight")
    assert_select("input#flight_trip_section[value=?]", flight.trip_section.to_s)
    assert_select("select#flight_origin_airport_id") do
      assert_select("option[selected=selected][value=?]", flight.origin_airport_id.to_s)
    end
    assert_select("select#flight_destination_airport_id") do
      assert_select("option[selected=selected][value=?]", flight.destination_airport_id.to_s)
    end
    flight.departure_date.strftime("%Y %-m %-d").split(" ").each_with_index do |d, i|
      assert_select("select#flight_departure_date_#{i+1}i") do
        assert_select("option[selected=selected][value=?]", d.to_s)
      end
    end
    flight.departure_utc.strftime("%Y %-m %-d %H %M").split(" ").each_with_index do |d, i|
      assert_select("select#flight_departure_utc_#{i+1}i") do
        assert_select("option[selected=selected][value=?]", d.to_s)
      end
    end
    assert_select("select#flight_airline_id") do
      assert_select("option[selected=selected][value=?]", flight.airline_id.to_s)
    end
    assert_select("input#flight_flight_number[value=?]", flight.flight_number.to_s)
    if flight.codeshare_airline_id
      assert_select("select#flight_codeshare_airline_id") do
        assert_select("option[selected=selected][value=?]", flight.codeshare_airline_id.to_s)
      end
    end
    if flight.codeshare_flight_number
      assert_select("input#flight_codeshare_flight_number[value=?]", flight.codeshare_flight_number.to_s)
    end
    if flight.aircraft_family_id
      assert_select("select#flight_aircraft_family_id") do
        assert_select("option[selected=selected][value=?]", flight.aircraft_family_id.to_s)
      end
    end
    if flight.tail_number
      assert_select("input#flight_tail_number[value=?]", TailNumber.format(flight.tail_number).to_s)
    end
    if flight.aircraft_name
      assert_select("input#flight_aircraft_name[value=?]", flight.aircraft_name.to_s)
    end
    if flight.operator_id
      assert_select("select#flight_operator_id") do
        assert_select("option[selected=selected][value=?]", flight.operator_id.to_s)
      end
    end
    if flight.fleet_number
      assert_select("input#flight_fleet_number[value=?]", flight.fleet_number.to_s)
    end
    if flight.travel_class
      assert_select("select#flight_travel_class") do
        assert_select("option[selected=selected][value=?]", flight.travel_class)
      end
    end
    if flight.comment
      assert_select("input#flight_comment[value=?]", flight.comment)
    end
    assert_select("textarea#flight_boarding_pass_data", flight.boarding_pass_data)
    assert_select("input[type=submit][value=?]", "Update Flight")
  end

  test "cannot see edit flight when not logged in" do
    flight = flights(:flight_ord_dfw)
    get(edit_flight_path(flight))
    assert_redirected_to(root_path)
  end

  private

  # Provides common assertions used in multiple new flight menu tests.
  def check_new_flight_menu_common(trip)
    assert_select("h1", "Create a New Flight")
    
    # E-mail a digital boarding pass:
    pk_pass = pk_passes(:icelandair_2019_08_31)
    assert_select("table#digital-boarding-passes") do
      assert_select("form", {count: PKPass.count})
      assert_select("tr#create-pk-pass-row-#{pk_pass.id}") do
        assert_select("form#create-pk-pass-form-#{pk_pass.id}") do
          assert_select("input#pk_pass_id[value=?]", pk_pass.id.to_s)
          assert_select("input#trip_id[value=?]", trip.id.to_s)
          assert_select("input[type=submit][value=?]", "Create this flight")
        end
        assert_select("a[data-method=delete][href=?]", pk_pass_path(pk_pass), {text: "Delete"})
      end
    end

    # Paste a barcode:
    assert_select("form#paste-bcbp") do
      assert_select("textarea#boarding_pass_data")
      assert_select("input#trip_id[value=?]", trip.id.to_s)
      assert_select("input[type=submit][value=?]", "Submit barcode data")
    end

    # Search for a flight number:
    assert_select("form#search-flight-number") do
      assert_select("select#airline_icao") do
        assert_select("option", {count: Airline.exclude_only_operators.count + 1}) # Includes blank option
      end
      assert_select("input#flight_number")
      assert_select("input#trip_id[value=?]", trip.id.to_s)
      assert_select("input[type=submit][value=?]", "Search")
    end

    # Create a flight manually:
    assert_select("form#create-flight-manually") do
      assert_select("input#trip_id[value=?]", trip.id.to_s)
      assert_select("input[type=submit][value=?]", "Create a new flight")
    end

  end

end