require "test_helper"

class FlightFlowsTest < ActionDispatch::IntegrationTest

  def setup
    @visible_flight = flights(:flight_visible)
    @hidden_flight = flights(:flight_hidden)

    @visible_tail = "N111VS"
    @hidden_tail = "N111HD"

    @visible_class = "economy"
    @hidden_class = "business"
  end
  
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

  ##############################################################################
  # Tests for Spec > Pages (Views) > Index Flights                             #
  ##############################################################################

  test "can see index flights when logged in" do
    log_in_as(users(:user_one))
    get(flights_path)
    assert_response(:success)

    check_index_flights_common
    assert_select("table#flight-table") do
      assert_select("tr#flight-row-#{@visible_flight.id}", {}, "This view shall show visible flights")
      assert_select("tr#flight-row-#{@hidden_flight.id}", {}, "This view shall show hidden flights")
      assert_select("td#flight-total", {text: /^#{logged_in_flights.count} flights?/}, "This view shall show a flight total row")
    end
  end

  test "can see index flights when not logged in" do
    get(flights_path)
    assert_response(:success)

    check_index_flights_common
    assert_select("table#flight-table") do
      assert_select("tr#flight-row-#{@visible_flight.id}", {}, "This view shall show visible flights")
      assert_select("tr#flight-row-#{@hidden_flight.id}", {count: 0}, "This view shall not show hidden flights when not logged in")
      assert_select("td#flight-total", {text: /^#{visitor_flights.count} flights?/}, "This view shall not include hidden flights in the total row")
    end
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Index Tail Numbers                        #
  ##############################################################################

  test "can see index tail numbers when logged in" do
    tails = TailNumber.flight_table_data(logged_in_flights)
    
    log_in_as(users(:user_one))
    get(tails_path)
    assert_response(:success)

    assert_select("h1", "Tail Numbers")

    assert_select("table#tail-number-count-table") do
      check_tail_number_row(tails, @visible_tail, "This view shall show tail numbers with visible flights")
      check_tail_number_row(tails, @hidden_tail, "This view shall show tail numbers with only hidden flights when logged in")
      assert_select("td#tail-number-count-total", {text: /^#{tails.size} unique tail numbers?/}, "Ranked tables shall have a total row with a correct total")
    end
  end

  test "can see index tail numbers when not logged in" do
    tails = TailNumber.flight_table_data(visitor_flights)

    get(tails_path)
    assert_response(:success)

    assert_select("h1", "Tail Numbers")

    assert_select("table#tail-number-count-table") do
      check_tail_number_row(tails, @visible_tail, "This view shall show tail numbers with visible flights")
      assert_select("td#tail-number-count-row-#{@hidden_tail}", {count: 0}, "This view shall not show tail numbers with only hidden flights when not logged in")
      assert_select("td#tail-number-count-total", {text: /^#{tails.size} unique tail numbers?/}, "Ranked tables shall have a total row with a correct total")
    end
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Index Travel Classes                      #
  ##############################################################################

  test "can see index travel classes when logged in" do
    classes = TravelClass.flight_table_data(logged_in_flights)
    
    log_in_as(users(:user_one))
    get(classes_path)
    assert_response(:success)

    assert_select("h1", "Travel Classes")

    assert_select("table#travel-class-count-table") do
      check_travel_class_row(classes, @visible_class, "This view shall show classes with visible flights")
      check_travel_class_row(classes, @hidden_class, "This view shall show classes with only hidden flights when logged in")
    end
  end

  test "can see index travel classes when not logged in" do
    classes = TravelClass.flight_table_data(visitor_flights)
    
    get(classes_path)
    assert_response(:success)

    assert_select("h1", "Travel Classes")

    assert_select("table#travel-class-count-table") do
      check_travel_class_row(classes, @visible_class, "This view shall show classes with visible flights")
      assert_select("tr#travel-class-count-row-#{@hidden_class}", {count: 0}, "This view shall not show classes with only hidden flights when not logged in")
    end
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Common to Every View > Tables > Flights   #
  #   Table                                                                    #
  ##############################################################################

  test "can see flight table partial" do
    log_in_as(users(:user_one))
    get(flights_path)
    assert_response(:success)
    # Removed until Index Flights uses flight table partial:
    # assert_template(layout: "layouts/application", partial: "_flight_table") # deprecated
    # assert_select("table#flight-table") do
    #   Tests a row within a Flights Table
    #   assert_select("tr#flight-row-#{flight.id}", {}, error_message) do
    #     assert_select("img.airline-icon")
    #     assert_select("a[href=?]", flight_path(flight), {text: "#{flight.airline.airline_name} #{flight.flight_number}"})
    #     assert_select("a[href=?]", airport_path(flight.origin_airport.slug), {text: flight.origin_airport.iata_code})
    #     assert_select("a[href=?]", airport_path(flight.destination_airport.slug), {text: flight.destination_airport.iata_code})
    #     assert_select("td.flight-date", {text: FormattedDate.str(flight.departure_date)})
    #   end
    # end
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

  # Provides common assertions used in multiple index flights tests.
  def check_index_flights_common
    assert_select("h1", "Flights")
    assert_select("div#flight-map", {}, "This view shall show a flight map")
    assert_select("table#flight-year-links", {}, "This view shall show year links")
  end

  # Runs tests on a row in a tail number count table
  def check_tail_number_row(flight_table_data, tail, error_message)
    tail_data = flight_table_data.find{|t| t[:tail_number] == tail}
    assert_select("tr#tail-number-count-row-#{tail}", {}, error_message) do
      assert_select("a[href=?]", show_tail_path(tail), {text: tail}) do
        assert_select("img.country-flag-icon")
      end
      assert_select("td.tail-aircraft", {text: tail_data[:aircraft]})
      assert_select("td.tail-airline") do
        assert_select("img.airline-icon[title=?]", tail_data[:airline_name])
      end
      assert_select("text.graph-value", tail_data[:count].to_s, "Graph bar shall have the correct flight count")
    end
  end

  def check_travel_class_row(flight_table_data, travel_class, error_message)
    tail_data = flight_table_data.find{|c| c[:class_code] == travel_class}
    assert_select("tr#travel-class-count-row-#{travel_class}", {}, error_message) do
      assert_select("a[href=?]", show_class_path(travel_class))
      assert_select("text.graph-value", tail_data[:flight_count].to_s, "Graph bar shall have the correct flight count")
    end
  end

end
