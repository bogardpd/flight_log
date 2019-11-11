require "test_helper"

class AirlineFlowsTest < ActionDispatch::IntegrationTest

  include ActionView::Helpers::NumberHelper
  
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
  # Tests for airline_count_table partial                                      #
  ##############################################################################

  test "can see index airlines when logged in" do
    airlines = Airline.flight_table_data(logged_in_flights, type: :airline).select{|airline| airline[:id].present?}
    operators = Airline.flight_table_data(logged_in_flights, type: :operator).select{|airline| airline[:id].present?}
    log_in_as(users(:user_one))
    get(airlines_path)
    assert_response(:success)

    verify_presence_of_admin_actions(new_airline_path)

    assert_select("h1", "Airlines")
    assert_select("table#airline-count-table") do
      check_airline_flight_row(@visible_airline, airlines.find{|a| a[:id] == @visible_airline.id}[:flight_count], "This view shall show airlines with visible flights")
      check_airline_flight_row(@hidden_airline, airlines.find{|a| a[:id] == @hidden_airline.id}[:flight_count], "This view shall show airlines with only hidden flights when logged in")
      assert_select("td#airline-count-total", {text: /^#{number_with_delimiter(airlines.size)} airlines?/}, "Airline ranked tables shall have a total row with a correct total")
    end

    assert_select("table#operator-count-table") do
      check_operator_flight_row(@visible_operator, operators.find{|a| a[:id] == @visible_operator.id}[:flight_count], "This view shall show operators with visible flights")
      check_operator_flight_row(@hidden_operator, operators.find{|a| a[:id] == @hidden_operator.id}[:flight_count], "This view shall show operators with only hidden flights when logged in")
      assert_select("td#operator-count-total", {text: /^#{number_with_delimiter(operators.size)} operators?/}, "Operator ranked tables shall have a total row with a correct total")
    end

    assert_select("table#airlines-with-no-flights-table") do
      assert_select("tr#airline-with-no-flights-row-#{@no_flights_airline.id}", {}, "This view shall show airlines with no flights when logged in") do
        assert_select("a[href=?]", airline_path(id: @no_flights_airline.slug))
      end
    end
    
  end

  test "can see index airlines when not logged in" do
    get(airlines_path)
    assert_response(:success)
    verify_absence_of_hidden_data
    verify_absence_of_admin_actions(new_airline_path)
    verify_absence_of_no_flights_tables
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Show Airline                              #
  ##############################################################################

  test "redirect show airline for unused or hidden airline when not logged in" do
    get(airline_path(airlines(:airline_no_flights).slug))
    assert_redirected_to(airlines_path)

    get(airline_path(airlines(:airline_hidden).slug))
    assert_redirected_to(airlines_path)
  end

  test "can see show airline for unused or hidden airline when logged in" do
    log_in_as(users(:user_one))

    get(airline_path(airlines(:airline_no_flights).slug))
    assert_response(:success)
    verify_presence_of_admin_actions(:delete)

    get(airline_path(airlines(:airline_hidden).slug))
    assert_response(:success)
  end
  
  test "can see show airline when logged in" do
    airline = airlines(:airline_american)
    log_in_as(users(:user_one))
    get(airline_path(airline.slug))
    assert_response(:success)

    check_show_airline_common(airline)
    verify_presence_of_admin_actions(edit_airline_path(airline))
  end

  test "can see show airline when not logged in" do
    airline = airlines(:airline_american)
    get(airline_path(airline.slug))
    assert_response(:success)

    check_show_airline_common(airline)
    verify_absence_of_hidden_data
    verify_absence_of_admin_actions(edit_airline_path(airline))
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Show Operator                             #
  ##############################################################################

  test "can see show operator" do
    operator = airlines(:airline_expressjet)
    get(show_operator_path(operator.slug))
    assert_response(:success)
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Show Fleet Number                         #
  ##############################################################################

  test "can see show fleet number" do
    operator = airlines(:airline_expressjet)
    fleet_number = "123"
    get(show_fleet_number_path(operator: operator.slug, fleet_number: fleet_number))
    assert_response(:success)
  end

  private

  # Runs tests on a row in an airline count table
  def check_airline_flight_row(airline, expected_flight_count, error_message)
    assert_select("tr#airline-count-row-#{airline.id}", {}, error_message) do
      assert_select("a[href=?]", airline_path(id: airline.slug))
      assert_select("text.graph-value", number_with_delimiter(expected_flight_count.to_s, delimiter: ","), "Graph bar shall have the correct flight count")
    end
  end

  # Runs tests on a row in an operator count table
  def check_operator_flight_row(operator, expected_flight_count, error_message)
    assert_select("tr#operator-count-row-#{operator.id}", {}, error_message) do
      assert_select("a[href=?]", show_operator_path(operator: operator.slug))
      assert_select("text.graph-value", number_with_delimiter(expected_flight_count.to_s, delimiter: ","), "Graph bar shall have the correct flight count")
    end
  end

  # Runs tests common to show airline
  def check_show_airline_common(airline)
    assert_select("h1", airline.airline_name)
    assert_select("#iata-airline-code", airline.iata_airline_code) if airline.iata_airline_code
    assert_select("#icao-airline-code", airline.icao_airline_code) if airline.icao_airline_code
    assert_select("div#map")

    assert_select("#operator-count-table")
    assert_select("#aircraft-family-count-table")
    assert_select("#travel-class-count-table")
    assert_select("#superlatives-table")
    assert_select("#flight-table")
  end

end
