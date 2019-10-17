require "test_helper"

class AirlineFlowsTest < ActionDispatch::IntegrationTest
  
  ##############################################################################
  # Tests for Spec > Pages (Views) > Add/Edit Airline                          #
  ##############################################################################

  test "can see add airline when logged in" do
    log_in_as(users(:user_one))
    get(new_airline_path)
    assert_response(:success)

    assert_select("h1", "New Airline")
    assert_select("form#new_airline")
    assert_select("input#airline_airline_name")
    assert_select("input#airline_iata_airline_code")
    assert_select("input#airline_icao_airline_code")
    assert_select("input#airline_numeric_code")
    assert_select("input#airline_is_only_operator")
    assert_select("input#airline_slug")
  end

  test "cannot see add airline when not logged in" do
    get(new_airline_path)
    assert_redirected_to(root_path)
  end

  test "can see edit airline when logged in" do
    airline = airlines(:airline_american)
    log_in_as(users(:user_one))
    get(edit_airline_path(airline))
    assert_response(:success)

    assert_select("h1", "Edit #{airline.airline_name}")
    assert_select("form#edit_airline_#{airline.id}")
    assert_select("input#airline_airline_name[value=?]", airline.airline_name)
    assert_select("input#airline_iata_airline_code[value=?]", airline.iata_airline_code)
    assert_select("input#airline_icao_airline_code[value=?]", airline.icao_airline_code)
    if airline.numeric_code
      assert_select("input#airline_numeric_code[value=?]", airline.numeric_code)
    else
      assert_select("input#airline_numeric_code")
    end
    if airline.is_only_operator
      assert_select("input#airline_is_only_operator[checked=checked]")
    else
      assert_select("input#airline_is_only_operator")
      assert_select("input#airline_is_only_operator[checked=checked]", {count: 0})
    end
    assert_select("input#airline_slug[value=?]", airline.slug)
  end

  test "cannot see edit airline when not logged in" do
    airline = airlines(:airline_american)
    get(edit_airline_path(airline))
    assert_redirected_to(root_path)
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Index Airlines                            #
  ##############################################################################

  test "can see index airlines when logged in" do
    log_in_as(users(:user_one))
    get(airlines_path)
    assert_response(:success)
  end

  test "can see index airlines when not logged in" do
    get(airlines_path)
    assert_response(:success)
  end

end
