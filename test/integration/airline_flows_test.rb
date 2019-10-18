require "test_helper"

class AirlineFlowsTest < ActionDispatch::IntegrationTest

  def setup
    @visible_airline = airlines(:airline_visible)
    @hidden_airline = airlines(:airline_hidden)
    @visible_operator = airlines(:operator_visible)
    @hidden_operator = airlines(:operator_hidden)
    @no_flights_airline = airlines(:airline_no_flights)
  end
  
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

    assert_select("h1", "Airlines")
    assert_select("table#airline-count-table") do
      check_airline_flight_row(@visible_airline, "This view should show airlines with visible flights")
      check_airline_flight_row(@hidden_airline, "This view should show airlines with only hidden flights when logged in")
    end
    assert_select("table#operator-count-table") do
      check_operator_flight_row(@visible_operator, "This view should show operators with visible flights")
      check_operator_flight_row(@hidden_operator, "This view should show operators with only hidden flights when logged in")
    end
    assert_select("table#airlines-with-no-flights-table") do
      assert_select("tr#airline-with-no-flights-row-#{@no_flights_airline.id}", {}, "This view should show airlines with no flights when logged in") do
        assert_select("a[href=?]", airline_path(id: @no_flights_airline.slug))
      end
    end

    assert_select("div#admin-actions", {}, "This view should show admin actions when logged in") do
      assert_select("a[href=?]", new_airline_path, {}, "This view should show a New Airline link when logged in")
    end

  end

  test "can see index airlines when not logged in" do
    get(airlines_path)
    assert_response(:success)

    assert_select("h1", "Airlines")
    assert_select("table#airline-count-table") do
      check_airline_flight_row(@visible_airline, "This view should show airlines with visible flights")
      assert_select("tr#airline-count-row-#{@hidden_airline.id}", {count: 0}, "This view should not show airlines with only hidden flights when not logged in")
    end
    assert_select("table#operator-count-table") do
      check_operator_flight_row(@visible_operator, "This view should show operators with visible flights")
      assert_select("tr#operator-count-row-#{@hidden_operator.id}", {count: 0}, "This view should not show operators with only hidden flights when not logged in")
    end
    assert_select("table#airlines-with-no-flights-table", {count: 0}, "This view should not show airlines with no flights when not logged in")

    assert_select("div#admin-actions", {count: 0}, "This view should not show admin actions when not logged in")
    assert_select("a[href=?]", new_airline_path, {count: 0}, "This view should not show a New Airline link when not logged in")

  end

  private

  def check_airline_flight_row(airline, error_message)
    assert_select("tr#airline-count-row-#{airline.id}", {}, error_message) do
      assert_select("a[href=?]", airline_path(id: airline.slug))
      assert_select("text.graph-value", airline.flights.count.to_s)
    end
  end

  def check_operator_flight_row(operator, error_message)
    assert_select("tr#operator-count-row-#{operator.id}", {}, error_message) do
      assert_select("a[href=?]", show_operator_path(operator: operator.slug))
      assert_select("text.graph-value", operator.operated_flights.count.to_s)
    end
  end

end
