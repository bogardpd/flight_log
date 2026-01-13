require "test_helper"

class TripFlowsTest < ActionDispatch::IntegrationTest

  def setup
    @visible_trip = trips(:trip_visible)
    @hidden_trip = trips(:trip_hidden)
    @no_flights_trip = trips(:trip_no_flights)

    @trip_params_new = {
      name: "Vacation",
      purpose: "Personal",
      comment: "This was a great vacation!",
      hidden: true,
    }
    @trip_params_update = {
      name: "New Name",
    }

    @extension_types = {
      'geojson' => "application/geo+json",
      'gpx'     => "application/gpx+xml",
      'graphml' => "application/xml",
      'kml'     => "application/vnd.google-earth.kml+xml",
    }
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
    assert_redirected_to(login_path)
  end

  test "can create trip when logged in" do
    log_in_as(users(:user_one))
    assert_difference("Trip.count", 1) do
      post(trips_path, params: {trip: @trip_params_new})
    end
    assert_redirected_to(trip_path(Trip.last))
    assert_equal(@trip_params_new[:name], Trip.last.name)
    assert_equal(@trip_params_new[:purpose], Trip.last.purpose)
    assert_equal(@trip_params_new[:comment], Trip.last.comment)
    assert_equal(@trip_params_new[:hidden], Trip.last.hidden)
    assert_equal(users(:user_one), Trip.last.user)
  end

  test "cannot create trip when not logged in" do
    assert_no_difference("Trip.count") do
      post(trips_path, params: {trip: @trip_params_new})
    end
    assert_redirected_to(login_path)
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
    assert_redirected_to(login_path)
  end

  test "can update trip when logged in" do
    log_in_as(users(:user_one))
    trip = trips(:trip_chicago_seattle)
    assert_no_difference("trip.flights.count") do
      patch(trip_path(trip), params: {trip: @trip_params_update})
    end
    assert_redirected_to(trip_path(trip))
    trip.reload
    assert_equal(@trip_params_update[:name], trip.name)
  end

  test "cannot update trip when not logged in" do
    trip = trips(:trip_chicago_seattle)
    original_name = trip.name
    assert_no_difference("trip.flights.count") do
      patch(trip_path(trip), params: {trip: @trip_params_update})
    end
    assert_redirected_to(login_path)
    trip.reload
    assert_equal(original_name, trip.name)
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

  test "cannot see index trips when not logged in" do
    get(trips_path)
    assert_redirected_to(login_path)
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Show Trip                                 #
  ##############################################################################

  test "cannot see show trip when not logged in" do
    trip = trips(:trip_chicago_seattle)
    get(trip_path(trip))
    assert_redirected_to(login_path)
  end

  test "can see show trip when logged in" do
    stub_aws_s3_get_timeout

    log_in_as(users(:user_one))
    trip = trips(:trip_hidden)
    get(trip_path(trip))
    assert_response(:success)
    verify_presence_of_admin_actions(new_flight_menu_path(trip), edit_trip_path(trip))

    assert_select("div#message-boarding-passes-available-for-import", {}, "This view shall show a link to import boarding passes")
  end

  test "can see show trip alternate map formats" do
    trip = trips(:trip_chicago_seattle)
    log_in_as(users(:user_one))
    @extension_types.each do |extension, type|
      get(trip_path(trip, map_id: "trip_map", extension: extension))
      assert_response(:success)
      assert_equal(type, response.media_type)
    end
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Show Trip Section                         #
  ##############################################################################

  test "cannot see show trip section when not logged in" do
    trip = trips(:trip_layover_ratios)
    section = 2
    get(show_section_path(trip: trip, section: section))
    assert_redirected_to(login_path)
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
    log_in_as(users(:user_one))
    @extension_types.each do |extension, type|
      get(show_section_path(trip: trip, section: section, map_id: "trip_section_map", extension: extension))
      assert_response(:success)
      assert_equal(type, response.media_type)
    end
  end

  ##############################################################################
  # Tests for deleting trips                                                   #
  ##############################################################################

  test "can destroy trip when logged in" do
    log_in_as(users(:user_one))
    trip = trips(:trip_no_flights)
    assert_difference("Trip.count", -1) do
      delete(trip_path(trip))
    end
    assert_redirected_to(trips_path)
  end

  test "cannot destroy trip when not logged in" do
    trip = trips(:trip_no_flights)
    assert_no_difference("Trip.count") do
      delete(trip_path(trip))
    end
    assert_redirected_to(login_path)
  end

  test "cannot destroy trip with flights" do
    log_in_as(users(:user_one))
    trip = flights(:flight_visible).trip

    assert_no_difference("Trip.count") do
      delete(trip_path(trip))
    end

    assert_redirected_to(trip_path(trip))
  end

end
