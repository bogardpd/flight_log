require "test_helper"

class TripFlowsTest < ActionDispatch::IntegrationTest
  
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

end
