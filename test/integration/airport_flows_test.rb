require "test_helper"

class AirportFlowsTest < ActionDispatch::IntegrationTest

  def setup
    @visible_airport = airports(:airport_visible_1)
    @hidden_airport = airports(:airport_hidden_1)
    @no_flights_airport = airports(:airport_no_flights)
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
    assert_select("input#airport_slug")
  end

  test "cannot see add airport when not logged in" do
    get(new_airport_path)
    assert_redirected_to(root_path)
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
    assert_select("input#airport_slug[value=?]",      airport.slug)
  end

  test "cannot see edit airport when not logged in" do
    airport = airports(:airport_dfw)
    get(edit_airport_path(airport))
    assert_redirected_to(root_path)
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Index Airports                            #
  # Tests for Spec > Common to Every View > Ranked Tables                      #
  ##############################################################################

  test "can see index airports when logged in" do
    visits = Airport.visit_frequencies(logged_in_flights)
    
    log_in_as(users(:user_one))
    get(airports_path)
    assert_response(:success)
    
    assert_select("h1", "Airports")

    assert_select("div#airports-map")
    assert_select("div#frequency-map")

    assert_select("table#airport-count-table") do
      check_flight_row(@visible_airport, visits[@visible_airport.id], "This view should show airports with visible flights")
      check_flight_row(@hidden_airport, visits[@hidden_airport.id], "This view should show airports with only hidden flights when logged in")
      assert_select("td#airport-count-total", {text: /^#{visits.size} airports?/}, "Ranked tables shall have a total row with a correct total")
    end

    assert_select("table#airports-with-no-flights-table") do
      assert_select("tr#airport-with-no-flights-row-#{@no_flights_airport.id}", {}, "This view should show airports with no flights when logged in") do
        assert_select("a[href=?]", airport_path(id: @no_flights_airport.slug))
      end
    end

    assert_select("div#admin-actions", {}, "This view should show admin actions when logged in") do
      assert_select("a[href=?]", new_airport_path, {}, "This view should show a New Airport link when logged in")
    end

  end

  test "can see index airports when not logged in" do
    visits = Airport.visit_frequencies(visitor_flights)
    
    get(airports_path)
    assert_response(:success)

    assert_select("h1", "Airports")

    assert_select("div#airports-map")
    assert_select("div#frequency-map")

    assert_select("table#airport-count-table") do
      check_flight_row(@visible_airport, visits[@visible_airport.id], "This view should show airports with visible flights")
      assert_select("tr#airport-count-row-#{@hidden_airport.id}", {count: 0}, "This view should not show airports with only hidden flights when not logged in")
      assert_select("td#airport-count-total", {text: /^#{visits.size} airports?/}, "Ranked tables shall have a total row with a correct total")
    end

    assert_select("table#airports-with-no-flights-table", {count: 0}, "This view should not show airports with no flights when not logged in")

    assert_select("div#admin-actions", {count: 0}, "This view should not show admin actions when not logged in")
    assert_select("a[href=?]", new_airport_path, {count: 0}, "This view should not show a New Airport link when not logged in")

  end

  private

  # Runs tests on a row in an airport count table
  def check_flight_row(airport, expected_visit_count, error_message)
    assert_select("tr#airport-count-row-#{airport.id}", {}, error_message) do
      assert_select("a[href=?]", airport_path(id: airport.slug))
      assert_select("text.graph-value", expected_visit_count.to_s, "Graph bar should have the correct flight count")
    end
  end

end
