require "test_helper"

class AirportFlowsTest < ActionDispatch::IntegrationTest

  def setup

    @visible_airport = airports(:airport_visible_1)
    @hidden_airport = airports(:airport_hidden_1)
    @no_flights_airport = airports(:airport_no_flights)

    @airport_params_new = {
      iata_code:   "HEL",
      icao_code:   "EFHK",
      city:        "Helsinki",
      country:     "Finland",
      slug:        "HEL",
      latitude:    60.31722,
      longitude:   24.96333
    }
    @airport_params_update = {
      city: "Fort Worth Dallas"
    }

    @extension_types = {
      'geojson' => "application/geo+json",
      'gpx'     => "application/gpx+xml",
      'graphml' => "application/xml",
      'kml'     => "application/vnd.google-earth.kml+xml",
    }
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Add/Edit Airport                          #
  ##############################################################################

  test "can see add airport when logged in" do
    log_in_as(users(:user_one))
    get(new_airport_path)
    assert_response(:success)

    assert_select("h1", "New Airport")
    assert_select("form#new_airport")
    assert_select("input#airport_iata_code")
    assert_select("input#airport_icao_code")
    assert_select("input#airport_city")
    assert_select("input#airport_country")
    assert_select("input#airport_latitude", {count: 0})
    assert_select("input#airport_longitude", {count: 0})
    assert_select("input#airport_slug")
  end

  test "cannot see add airport when not logged in" do
    get(new_airport_path)
    assert_redirected_to(login_path)
  end

  test "can create airport when logged in" do
    log_in_as(users(:user_one))
    assert_difference("Airport.count", 1) do
      post(airports_path, params: { airport: @airport_params_new })
    end
    new_airport = Airport.find_by(slug: @airport_params_new[:slug])
    assert_redirected_to(airport_path(new_airport.slug))
    assert_equal(@airport_params_new[:iata_code], new_airport.iata_code)
    assert_equal(@airport_params_new[:icao_code], new_airport.icao_code)
    assert_equal(@airport_params_new[:city], new_airport.city)
    assert_equal(@airport_params_new[:country], new_airport.country)
    assert_equal(@airport_params_new[:latitude], new_airport.latitude)
    assert_equal(@airport_params_new[:longitude], new_airport.longitude)
  end

  test "cannot create airport when not logged in" do
    assert_no_difference("Airport.count") do
      post(airports_path, params: { airport: @airport_params_new })
    end
    assert_redirected_to(login_path)
  end

  test "can see edit airport when logged in" do
    airport = airports(:airport_dfw)
    log_in_as(users(:user_one))
    get(edit_airport_path(airport))
    assert_response(:success)

    assert_select("h1", "Edit #{airport.iata_code}")
    assert_select("form#edit_airport_#{airport.id}")
    assert_select("input#airport_iata_code[value=?]", airport.iata_code)
    assert_select("input#airport_icao_code[value=?]", airport.icao_code)
    assert_select("input#airport_city[value=?]",      airport.city)
    assert_select("input#airport_country[value=?]",   airport.country)
    assert_select("input#airport_latitude[value=?]",  airport.latitude.to_s)
    assert_select("input#airport_longitude[value=?]", airport.longitude.to_s)
    assert_select("input#airport_slug[value=?]",      airport.slug)
  end

  test "cannot see edit airport when not logged in" do
    airport = airports(:airport_dfw)
    get(edit_airport_path(airport))
    assert_redirected_to(login_path)
  end

  test "can update airport when logged in" do
    airport = airports(:airport_dfw)
    log_in_as(users(:user_one))
    patch(airport_path(airport), params: { airport: @airport_params_update })
    assert_redirected_to(airport_path(airport.slug))
    airport.reload
    assert_equal(@airport_params_update[:city], Airport.find(airport.id).city)
  end

  test "cannot update airport when not logged in" do
    airport = airports(:airport_dfw)
    original_city = airport.city
    patch(airport_path(airport), params: { airport: @airport_params_update })
    assert_redirected_to(login_path)
    airport.reload
    assert_equal(original_city, Airport.find(airport.id).city)
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Index Airports                            #
  # Tests for airport_count_table partial                                      #
  ##############################################################################

  test "can see index airports when logged in" do
    visits = Airport.visit_frequencies(logged_in_flights)

    log_in_as(users(:user_one))
    get(airports_path)
    assert_response(:success)

    verify_presence_of_admin_actions(new_airport_path)

    assert_select("h1", "Airports")

    assert_select("div#airports_map")
    assert_select("div#frequency_map")

    assert_select("table#airport-count-table") do
      check_flight_row(@visible_airport, visits[@visible_airport.id], "This view shall show airports with visible flights")
      check_flight_row(@hidden_airport, visits[@hidden_airport.id], "This view shall show airports with only hidden flights when logged in")
      assert_select("td#airport-count-total[data-total=?]", visits.size.to_s, {}, "Ranked tables shall have a total row with a correct total")
    end

    assert_select("table#airports-with-no-flights-table") do
      assert_select("tr#airport-with-no-flights-row-#{@no_flights_airport.id}", {}, "This view shall show airports with no flights when logged in") do
        assert_select("a[href=?]", airport_path(id: @no_flights_airport.slug))
      end
    end

  end

  test "can see index airports when not logged in" do
    get(airports_path)
    assert_response(:success)
    verify_absence_of_hidden_data
    verify_absence_of_admin_actions(new_airport_path)
    verify_absence_of_no_flights_tables
  end

  test "can see index airport alternate map formats" do
    %w(gpx kml geojson).each do |extension|
      %w(airports_map frequency_map).each do |map_id|
        get(airports_path(map_id: map_id, extension: extension))
        assert_response(:success)
        assert_equal(@extension_types[extension], response.media_type)
      end
    end
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Show Airport                              #
  ##############################################################################

  test "redirect show unused or hidden airports when appropriate" do
    verify_show_unused_or_hidden_redirects(
      show_unused_path: airport_path(airports(:airport_no_flights).slug),
      show_hidden_path: airport_path(airports(:airport_hidden_1).slug),
      redirect_path:    airports_path
    )
  end

  test "can see show airport when logged in" do
    airport = airports(:airport_visible_1)
    log_in_as(users(:user_one))
    get(airport_path(airport.slug))
    assert_response(:success)

    check_show_airport_common(airport)
    verify_presence_of_admin_actions(edit_airport_path(airport))
  end

  test "can see show airport when not logged in" do
    airport = airports(:airport_visible_1)
    get(airport_path(airport.slug))
    assert_response(:success)

    check_show_airport_common(airport)
    verify_absence_of_hidden_data
    verify_absence_of_admin_actions(edit_airport_path(airport))
  end

  test "can see show airport alternate map formats" do
    airport = airports(:airport_visible_1)
    @extension_types.each do |extension, type|
      %w(airport_map sections_map trips_map).each do |map_id|
        get(airport_path(airport.slug, map_id: map_id, extension: extension))
        assert_response(:success)
        assert_equal(type, response.media_type)
      end
    end
  end

  ##############################################################################
  # Tests for deleting airports                                                #
  ##############################################################################

  test "can destroy airport when logged in" do
    log_in_as(users(:user_one))
    airport = airports(:airport_no_flights)
    assert_difference("Airport.count", -1) do
      delete(airport_path(airport))
    end
    assert_redirected_to(airports_path)
  end

  test "cannot destroy airport when not logged in" do
    airport = airports(:airport_no_flights)
    assert_no_difference("Airport.count") do
      delete(airport_path(airport))
    end
    assert_redirected_to(login_path)
  end

  test "cannot remove airport with flights" do
    log_in_as(users(:user_one))
    airport = flights(:flight_visible).origin_airport

    assert_no_difference("Airport.count") do
      delete(airport_path(airport))
    end

    assert_redirected_to(airport_path(airport.slug))
  end

  private

  # Runs tests on a row in an airport count table
  def check_flight_row(airport, expected_visit_count, error_message)
    assert_select("tr#airport-count-row-#{airport.id}", {}, error_message) do
      assert_select("a[href=?]", airport_path(id: airport.slug))
      assert_select("text.graph-value[data-value=?]", expected_visit_count.to_s, {}, "Graph bar shall have the correct flight count")
    end
  end

  # Runs tests common to show airport
  def check_show_airport_common(airport)
    assert_select("h1", airport.city)

    assert_select("#summary-value-coordinates") if airport.latitude && airport.longitude
    assert_select("#summary-value-iata", airport.iata_code) if airport.iata_code
    assert_select("#summary-value-icao", airport.icao_code) if airport.icao_code

    assert_select("#airport_map")
    assert_select("#trips_map")
    assert_select("#sections_map")

    assert_select(".distance-mi")

    assert_select("#flight-table")
    assert_select("#trip-and-section-table")

    assert_select("#airline-count-table")
    assert_select("#operator-count-table")
    assert_select("#aircraft-family-count-table")
    assert_select("#travel-class-count-table")

    assert_select("#nonstop-flight-airports-table")
  end

end
