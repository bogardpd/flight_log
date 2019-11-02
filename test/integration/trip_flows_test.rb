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
  ##############################################################################

  test "can see index trips when logged in" do
    log_in_as(users(:user_one))
    get(trips_path)
    assert_response(:success)

    assert_select("h1", "Trips")

    assert_select("table#trips-table") do
      assert_select("tr#trip-row-#{@visible_trip.id}", {}, "This view shall show visible trips")
      assert_select("tr#trip-row-#{@hidden_trip.id}", {}, "This view shall show hidden trips when logged in")
    end

    assert_select("table#trips-with-no-flights-table") do
      assert_select("tr#trip-with-no-flights-row-#{@no_flights_trip.id}", {}, "This view shall show trips with no flights when logged in")
    end

    assert_select("div#admin-actions", {}, "This view shall show admin actions when logged in") do
      assert_select("a[href=?]", new_trip_path, {}, "This view shall show a New Trip link when logged in")
    end
  end

  test "can see index trips when not logged in" do
    get(trips_path)
    assert_response(:success)

    assert_select("h1", "Trips")

    assert_select("table#trips-table") do
      assert_select("tr#trip-row-#{@visible_trip.id}", {}, "This view shall show visible trips")
      assert_select("tr#trip-row-#{@hidden_trip.id}", {count: 0}, "This view shall not show hidden trips when not logged in")
    end

    assert_select("table#trips-with-no-flights-table", {count: 0}, "This view shall not show trips with no flights when not logged in")

    assert_select("div#admin-actions", {count: 0}, "This view shall not show admin actions when not logged in")
    assert_select("a[href=?]", new_trip_path, {count: 0}, "This view shall not show a New Trip link when not logged in")
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Common to Every View > Tables > Trips     #
  #   Table and Trip Sections Table                                            #
  ##############################################################################

  test "can see trips table partial" do
    trips = Trip.with_departure_dates(users(:user_one), users(:user_one))
    
    log_in_as(users(:user_one))
    get(trips_path)
    assert_response(:success)

    assert_select("table#trips-table") do
      assert_select("tr#trip-row-#{@visible_trip.id}") do
        assert_select("a[href=?]", trip_path(@visible_trip), {text: @visible_trip.name})
        assert_select("td.flight-date", {text: FormattedDate.str(@visible_trip.flights.pluck(:departure_date).sort.first)})
      end
      assert_select("tr#trip-row-#{@hidden_trip.id}") do
        assert_select("div.hidden-marker", {}, "Hidden trip shall have hidden marker")
      end
      assert_select("td#trips-total", {text: /^#{trips.size} trips?/}, "Trips table shall have a total row with a correct total")
    end
  end

end
