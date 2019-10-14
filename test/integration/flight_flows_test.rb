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
