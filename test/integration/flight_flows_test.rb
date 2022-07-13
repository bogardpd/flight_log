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
  # Tests for Spec > Pages (Views) > Common to Every View > Tables > Flight    #
  #   Table                                                                    #
  # Tests for flight_table partial                                             #
  # Tests for flight_year_links partial                                        #
  ##############################################################################

  test "can see index flights when logged in" do
    log_in_as(users(:user_one))
    get(flights_path)
    assert_response(:success)
    
    assert_select("h1", "Flights")
    assert_select("div#flights_map", {}, "This view shall show a flight map")
    assert_select("table#flight-year-links", {}, "This view shall show year links") do
      assert_select("a[href=?]", show_year_path(@visible_flight.departure_date.year))
    end

    assert_select("table#flight-table") do
      assert_select("tr#flight-row-#{@visible_flight.id}", {}, "This view shall show visible flights")
      assert_select("tr#flight-row-#{@hidden_flight.id}", {}, "This view shall show hidden flights")
      assert_select("td#flight-total[data-total=?]", logged_in_flights.count.to_s, {}, "This view shall show a flight total row")
    end
  end

  test "can see index flights when not logged in" do
    get(flights_path)
    assert_response(:success)
    verify_absence_of_hidden_data
  end

  test "can see index flight alternate map formats" do
    %w(gpx kml).each do |extension|
      get(flights_path(map_id: "flights_map", extension: extension))
      assert_response(:success)
      assert_equal("application/xml", response.media_type)
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
      assert_select("td#tail-number-count-total[data-total=?]", tails.size.to_s, {}, "Ranked tables shall have a total row with a correct total")
    end
  end

  test "can see index tail numbers when not logged in" do
    get(tails_path)
    assert_response(:success)
    verify_absence_of_hidden_data    
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Index Travel Classes                      #
  # Tests for class_count_table partial                                        #
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
    get(classes_path)
    assert_response(:success)
    verify_absence_of_hidden_data
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Show Date Range                           #
  ##############################################################################

  test "redirect show hidden date range when appropriate" do
    verify_show_unused_or_hidden_redirects(
      show_hidden_path: show_date_range_path(start_date: @hidden_flight.departure_date, end_date: @hidden_flight.departure_date),
      redirect_path:    flights_path
    )
  end

  test "can see show date range when not logged in" do
    get(show_date_range_path(start_date: "2014-07-01", end_date: "2015-06-30"))
    assert_response(:success)
    verify_absence_of_hidden_data

    assert_select(".flights-map")
    assert_select("#flight-table")
    assert_select(".distance-mi")
    assert_select("#airport-count-table")
    assert_select("#airline-count-table")
    assert_select("#operator-count-table")
    assert_select("#aircraft-family-count-table")
    assert_select("#superlatives-table")
  end

  test "can see show date range when logged in" do
    log_in_as(users(:user_one))
    get(show_date_range_path(start_date: "2014-07-01", end_date: "2015-06-30"))
    assert_response(:success)
  end

  test "can see show date range with leading zero" do
    # Leading 0s in date strings can be confused for an octal number, which is a
    # problem if subsequent digits are greater than 7.
    get(show_date_range_path(start_date: "2014-09-01", end_date: "2015-06-30"))
    assert_response(:success)
  end

  test "can see show date range alternate map formats" do
    date_range = {start_date: "2014-07-01", end_date: "2015-06-30"}
    %w(gpx kml).each do |extension|
      get(show_date_range_path(**date_range, map_id: "date_range_map", extension: extension))
      assert_response(:success)
      assert_equal("application/xml", response.media_type)
    end
  end

  test "can see show date range with year" do
    get(show_year_path(2015))
    assert_response(:success)
  end

  test "can see show date range with year alternate map formats" do
    year = 2015
    %w(gpx kml).each do |extension|
      get(show_year_path(year, map_id: "date_range_map", extension: extension))
      assert_response(:success)
      assert_equal("application/xml", response.media_type)
    end
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Show Flight                               #
  # Tests for bcbp partial                                                     #
  ##############################################################################

  test "redirect show hidden flights when appropriate" do
    verify_show_unused_or_hidden_redirects(
      show_hidden_path: flight_path(@hidden_flight),
      redirect_path:    flights_path
    )
  end

  test "can see show flight when logged in" do
    flight = flights(:flight_ord_dfw)
    log_in_as(users(:user_one))
    get(flight_path(flight))
    assert_response(:success)

    check_show_flight_common(flight)
    verify_presence_of_admin_actions(edit_flight_path(flight))
    assert_select("#flight-boarding-pass-data")
  end

  test "can see show flight when not logged in" do
    flight = flights(:flight_ord_dfw)
    get(flight_path(flight))
    assert_response(:success)

    check_show_flight_common(flight)
    verify_absence_of_hidden_data
    verify_absence_of_admin_actions(edit_flight_path(flight))
    assert_select("#flight-boarding-pass-data", {count: 0})
  end

  test "can see show flight alternate map formats" do
    flight = flights(:flight_ord_dfw)
    %w(gpx kml).each do |extension|
      get(flight_path(flight, map_id: "flight_map", extension: extension))
      assert_response(:success)
      assert_equal("application/xml", response.media_type)
    end
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Show Tail Number                          #
  ##############################################################################
  
  test "redirect show hidden tail number when appropriate" do
    verify_show_unused_or_hidden_redirects(
      show_hidden_path: show_tail_path(@hidden_flight.tail_number),
      redirect_path:    tails_path
    )
  end
  
  test "can see show tail number when not logged in" do
    tail = @visible_flight.tail_number
    get(show_tail_path(tail))
    assert_response(:success)
    verify_absence_of_hidden_data

    assert_select(".flights-map")
    assert_select("#flight-table")
    assert_select(".distance-mi")
    assert_select("#travel-class-count-table")
    assert_select("#airline-count-table")
    assert_select("#operator-count-table")
    assert_select("#superlatives-table")

    assert_select("a[href=?]", "http://flightaware.com/live/flight/#{tail}")
  end

  test "can see show tail number when logged in" do
    log_in_as(users(:user_one))
    get(show_tail_path(@visible_flight.tail_number))
    assert_response(:success)
  end

  test "can see show tail number alternate map formats" do
    tail = @visible_flight.tail_number
    %w(gpx kml).each do |extension|
      get(show_tail_path(tail, map_id: "tail_map", extension: extension))
      assert_response(:success)
      assert_equal("application/xml", response.media_type)
    end
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Show Travel Class                         #
  ##############################################################################

  test "redirect show hidden travel class when appropriate" do
    verify_show_unused_or_hidden_redirects(
      show_hidden_path: show_class_path(@hidden_flight.travel_class),
      redirect_path:    classes_path
    )
  end
  
  test "can see show travel class when not logged in" do
    get(show_class_path("economy"))
    assert_response(:success)
    verify_absence_of_hidden_data

    assert_select(".flights-map")
    assert_select("#flight-table")
    assert_select(".distance-mi")
    assert_select("#airline-count-table")
    assert_select("#operator-count-table")
    assert_select("#aircraft-family-count-table")
    assert_select("#superlatives-table")
  end

  test "can see show travel class when logged in" do
    log_in_as(users(:user_one))
    get(show_class_path("economy"))
    assert_response(:success)
  end

  test "can see show travel class alternate map formats" do
    travel_class = "economy"
    %w(gpx kml).each do |extension|
      get(show_class_path(travel_class, map_id: "travel_class_map", extension: extension))
      assert_response(:success)
      assert_equal("application/xml", response.media_type)
    end
  end

  ##############################################################################
  # Tests to ensure visitors can't create, update, or destroy flights          #
  ##############################################################################

  test "visitor cannot create, update, or destroy flights" do
    verify_create_update_destroy_redirects(
      flights_path,
      flight_path(@visible_flight)
    )
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
        assert_select("a[data-method=delete][href=?]", p_k_pass_path(pk_pass), {text: "Delete"})
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
      assert_select("text.graph-value[data-value=?]", tail_data[:count].to_s, {}, "Graph bar shall have the correct flight count")
    end
  end

  def check_travel_class_row(flight_table_data, travel_class, error_message)
    class_data = flight_table_data.find{|c| c[:class_code] == travel_class}
    assert_select("tr#travel-class-count-row-#{travel_class}", {}, error_message) do
      assert_select("a[href=?]", show_class_path(travel_class))
      assert_select("text.graph-value[data-value=?]", class_data[:flight_count].to_s, {}, "Graph bar shall have the correct flight count")
    end
  end

  # Runs tests common to show airline
  def check_show_flight_common(flight)
    assert_select("h1", flight.name)
    
    assert_select("#flight-airline") do
      assert_select("a[href=?]", airline_path(flight.airline.slug), {text: flight.airline.name})
    end
    assert_select("#flight-trip") do
      assert_select("a[href=?]", trip_path(flight.trip), {text: flight.trip.name})
      assert_select("a[href=?]", show_section_path(flight.trip, flight.trip_section), {text: "Section #{flight.trip_section}"})
    end
    assert_select("#flight-route") do
      assert_select("a[href=?]", show_route_path(flight.origin_airport.slug,flight.destination_airport.slug), {text: Route.airport_string(flight.origin_airport, flight.destination_airport, sort: false)})
      assert_select("#flight-route-distance")
    end
    assert_select("#flight-departure-date", {text: NumberFormat.date(flight.departure_date)})
    assert_select("#flight-origin-airport") do
      assert_select("a[href=?]", airport_path(flight.origin_airport.slug), {text: flight.origin_airport.city})
    end
    assert_select("#flight-destination-airport") do
      assert_select("a[href=?]", airport_path(flight.destination_airport.slug), {text: flight.destination_airport.city})
    end
    assert_select("#flight-aircraft") do
      assert_select("a[href=?]", aircraft_family_path(flight.aircraft_family.slug), {text: flight.aircraft_family.name})
      assert_select("a[href=?]", aircraft_family_path(flight.aircraft_family.parent.slug), {text: "#{flight.aircraft_family.parent.manufacturer} #{flight.aircraft_family.parent.name}"})
    end
    assert_select("#flight-tail-number") do
      assert_select("a[href=?]", show_tail_path(flight.tail_number), {text: flight.tail_number})
    end
    assert_select("#flight-travel-class") do
      assert_select("a[href=?]", show_class_path(flight.travel_class), {text: TravelClass::CLASSES[flight.travel_class][:name].titlecase})
    end
    assert_select("#flight-codeshare") do
      assert_select("#flight-codeshare-airline", {text: flight.codeshare_airline.name})
      assert_select("#flight-codeshare-flight-number", {text: flight.codeshare_flight_number})
    end
    assert_select("#flight-operator") do
      assert_select("a[href=?]", show_operator_path(flight.operator.slug), {text: flight.operator.name})
      assert_select("a[href=?]", show_fleet_number_path(flight.operator.slug, flight.fleet_number), {text: "##{flight.fleet_number}"})
    end
    assert_select("#flight-aircraft-name", {text: flight.aircraft_name})
    assert_select("p.comment", {text: flight.comment})

    assert_select(".single-flight-map")
  end

  # Returns the count of waypoints of a given airport in a GPX file.
  def gpx_airport_count(gpx, airport_to_find)
    airports = Hash.from_xml(gpx).dig("gpx", "wpt")
    count = airports.select{|a| a["description"] == airport_to_find.city}.size
  end

  # Returns the count of waypoints of a given airport in a GPX file.
  def kml_airport_count(kml, airport_to_find)
    airports = Hash.from_xml(kml).dig("kml", "Document", "Folder").find{|f| f["name"] == "Airports"}.dig("Placemark")
    count = airports.select{|a| a["description"] == airport_to_find.city}.size
  end

end
