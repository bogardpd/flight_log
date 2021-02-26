require "test_helper"

class TripFlowsTest < ActionDispatch::IntegrationTest

  def setup
    @visible_trip = trips(:trip_visible)
    @hidden_trip = trips(:trip_hidden)
    @no_flights_trip = trips(:trip_no_flights)
  end
  
  ##############################################################################
  # Tests for Spec > Pages (Views) > Add/Edit Trip                             #
  ##############################################################################

  test "can see add trip when logged in" do
    log_in_as(users(:user_one))
    get(new_trip_path)
    assert_response(:success)

    assert_select("h1", "New Trip")
    assert_select("input#trip_name")
    assert_select("select#trip_purpose") do
      assert_select("option", {count: Trip::PURPOSES.size + 1})
    end
    assert_select("input#trip_hidden")
    assert_select("input#trip_comment")
    assert_select("input[type=submit][value=?]", "Add Trip")
  end

  test "cannot see add trip when not logged in" do
    get(new_trip_path)
    assert_redirected_to(root_path)
  end

  test "can see edit trip when logged in" do
    log_in_as(users(:user_one))
    trip = trips(:trip_chicago_seattle)
    get(edit_trip_path(trip))
    assert_response(:success)

    assert_select("h1", "Edit #{trip.name}")
    assert_select("input#trip_name[value=?]", trip.name.to_s)
    assert_select("select#trip_purpose") do
      assert_select("option[selected=selected][value=?]", trip.purpose)
    end
    if trip.hidden
      assert_select("input#trip_hidden[checked=checked]")
    else
      assert_select("input#trip_hidden")
      assert_select("input#trip_hidden[checked=checked]", {count: 0})
    end
    if trip.comment
      assert_select("input#trip_comment[value=?]", trip.comment)
    end
    assert_select("input[type=submit][value=?]", "Update Trip")
  end

  test "cannot see edit trip when not logged in" do
    trip = trips(:trip_chicago_seattle)
    get(edit_trip_path(trip))
    assert_redirected_to(root_path)
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Index Trips                               #
  # Tests for Spec > Pages (Views) > Common to Every View > Tables > Trips     #
  #   Table and Trip Sections Table                                            #
  # Tests for trip_table partial                                               #
  ##############################################################################

  test "can see index trips when logged in" do
    trips = Trip.with_departure_dates(users(:user_one), users(:user_one))
    
    log_in_as(users(:user_one))
    get(trips_path)
    assert_response(:success)

    verify_presence_of_admin_actions(new_trip_path)

    assert_select("h1", "Trips")

    assert_select("table#trips-table") do
      assert_select("tr#trip-row-#{@visible_trip.id}", {}, "This view shall show visible trips") do
        assert_select("a[href=?]", trip_path(@visible_trip), {text: @visible_trip.name})
        assert_select("td.flight-date", {text: NumberFormat.date(@visible_trip.flights.pluck(:departure_date).sort.first)})
      end
      assert_select("tr#trip-row-#{@hidden_trip.id}", {}, "This view shall show hidden trips when logged in") do
        assert_select("div.hidden-marker", {}, "Hidden trip shall have hidden marker")
      end
      assert_select("td#trips-total[data-total=?]", trips.size.to_s, {}, "Trips table shall have a total row with a correct total")
    end

    assert_select("table#trips-with-no-flights-table") do
      assert_select("tr#trip-with-no-flights-row-#{@no_flights_trip.id}", {}, "This view shall show trips with no flights when logged in")
    end
    
  end

  test "can see index trips when not logged in" do
    get(trips_path)
    assert_response(:success)
    verify_absence_of_hidden_data
    verify_absence_of_admin_actions(new_trip_path)
    verify_absence_of_no_flights_tables
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Show Trip                                 #
  ##############################################################################

  test "redirect show unused or hidden trips when appropriate" do
    verify_show_unused_or_hidden_redirects(
      show_unused_path: trip_path(@no_flights_trip),
      show_hidden_path: trip_path(@hidden_trip),
      redirect_path:    trips_path
    )
  end

  test "can see show trip when not logged in" do
    trip = trips(:trip_chicago_seattle)
    get(trip_path(trip))
    assert_response(:success)
    verify_absence_of_hidden_data
    verify_absence_of_admin_actions(new_flight_menu_path(trip), edit_trip_path(trip))

    assert_select(".flights-map")
    assert_select(".distance-mi")
    assert_select("table#trip-flight-table") do
      assert_select("td.flight-section", {count: trip.flights.pluck(:trip_section).uniq.size})
      assert_select("td.flight-flight", {count: trip.flights.size})
    end

    assert_select("div#message-boarding-passes-available-for-import", {count: 0}, "This view shall not show a link to import boarding passes")
  end

  test "can see show trip when logged in" do
    log_in_as(users(:user_one))
    trip = trips(:trip_hidden)
    get(trip_path(trip))
    assert_response(:success)
    verify_presence_of_admin_actions(new_flight_menu_path(trip), edit_trip_path(trip))

    assert_select("div#message-boarding-passes-available-for-import", {}, "This view shall show a link to import boarding passes")
  end

  test "can see show trip alternate map formats" do
    trip = trips(:trip_chicago_seattle)
    %w(gpx kml).each do |extension|
      get(trip_path(trip, map_id: "trip_map", extension: extension))
      assert_response(:success)
      assert_equal("application/xml", response.media_type)
    end
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Show Trip Section                         #
  ##############################################################################

  test "redirect show hidden trip sections when appropriate" do
    verify_show_unused_or_hidden_redirects(
      show_hidden_path: trip_path(@hidden_trip, 1),
      redirect_path:    trips_path
    )
  end
  
  test "can see show trip section when not logged in" do
    trip = trips(:trip_layover_ratios)
    section = 2
    get(show_section_path(trip: trip, section: section))
    assert_response(:success)
    verify_absence_of_hidden_data

    assert_select(".flights-map")
    assert_select("#flight-table")
    assert_select(".distance-mi")
    assert_select("#summary-value-layover-ratio")
  end

  test "can see show trip section when logged in" do
    trip = trips(:trip_chicago_seattle)
    section = 1
    log_in_as(users(:user_one))
    get(show_section_path(trip: trip, section: section))
    assert_response(:success)
  end

  test "can see show trip section alternate map formats" do
    trip = trips(:trip_chicago_seattle)
    section = 1
    %w(gpx kml).each do |extension|
      get(show_section_path(trip: trip, section: section, map_id: "trip_section_map", extension: extension))
      assert_response(:success)
      assert_equal("application/xml", response.media_type)
    end
  end

  ##############################################################################
  # Tests to ensure visitors can't create, update, or destroy trips            #
  ##############################################################################

  test "visitor cannot create, update, or destroy trips" do
    verify_create_update_destroy_redirects(
      trips_path,
      trip_path(@visible_trip)
    )
  end

  ##############################################################################
  # Tests to ensure users can't destroy trips with flights                     #
  ##############################################################################

  test "cannot remove trip with flights" do
    log_in_as(users(:user_one))
    trip = flights(:flight_visible).trip
    
    assert_no_difference("Trip.count") do
      delete(trip_path(trip))
    end
    
    assert_redirected_to(trip_path(trip))
  end

end
