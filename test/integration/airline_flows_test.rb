require "test_helper"

class AirlineFlowsTest < ActionDispatch::IntegrationTest

  def setup
    @visible_airline = airlines(:airline_visible)
    @hidden_airline = airlines(:airline_hidden)
    @visible_operator = airlines(:operator_visible)
    @hidden_operator = airlines(:operator_hidden)
    @no_flights_airline = airlines(:airline_no_flights)
    @visible_flight = flights(:flight_visible)
    @hidden_flight = flights(:flight_hidden)
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
    assert_select("input#airline_name")
    assert_select("input#airline_iata_code")
    assert_select("input#airline_icao_code")
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

    assert_select("h1", "Edit #{airline.name}")
    assert_select("form#edit_airline_#{airline.id}")
    assert_select("input#airline_name[value=?]", airline.name)
    assert_select("input#airline_iata_code[value=?]", airline.iata_code)
    assert_select("input#airline_icao_code[value=?]", airline.icao_code)
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
      assert_select("td#airline-count-total[data-total=?]", airlines.size.to_s, {}, "Airline ranked tables shall have a total row with a correct total")
    end

    assert_select("table#operator-count-table") do
      check_operator_flight_row(@visible_operator, operators.find{|a| a[:id] == @visible_operator.id}[:flight_count], "This view shall show operators with visible flights")
      check_operator_flight_row(@hidden_operator, operators.find{|a| a[:id] == @hidden_operator.id}[:flight_count], "This view shall show operators with only hidden flights when logged in")
      assert_select("td#operator-count-total[data-total=?]", operators.size.to_s, {}, "Operator ranked tables shall have a total row with a correct total")
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

  test "redirect show unused or hidden airlines when appropriate" do
    verify_show_unused_or_hidden_redirects(
      show_unused_path: airline_path(airlines(:airline_no_flights).slug),
      show_hidden_path: airline_path(airlines(:airline_hidden).slug),
      redirect_path:    airlines_path
    )
  end
  
  test "can see show airline when logged in" do
    airline = airlines(:airline_american)
    log_in_as(users(:user_one))
    get(airline_path(airline.slug))
    assert_response(:success)

    check_show_airline_common(airline, :airline)
    verify_presence_of_admin_actions(edit_airline_path(airline))
  end

  test "can see show airline when not logged in" do
    airline = airlines(:airline_american)
    get(airline_path(airline.slug))
    assert_response(:success)

    check_show_airline_common(airline, :airline)
    verify_absence_of_hidden_data
    verify_absence_of_admin_actions(edit_airline_path(airline))
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Show Operator                             #
  ##############################################################################

  test "redirect show unused or hidden operators when appropriate" do
    verify_show_unused_or_hidden_redirects(
      show_unused_path: show_operator_path(airlines(:airline_no_flights).slug),
      show_hidden_path: show_operator_path(airlines(:operator_hidden).slug),
      redirect_path:    airlines_path
    )
  end
  
  test "can see show operator when logged in" do
    operator = airlines(:airline_american)
    log_in_as(users(:user_one))
    get(show_operator_path(operator.slug))
    assert_response(:success)

    check_show_airline_common(operator, :operator)
    verify_presence_of_admin_actions(edit_airline_path(operator))
  end

  test "can see show operator when not logged in" do
    operator = airlines(:airline_american)
    get(show_operator_path(operator.slug))
    assert_response(:success)

    check_show_airline_common(operator, :operator)
    verify_absence_of_hidden_data
    verify_absence_of_admin_actions(edit_airline_path(operator))
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Show Fleet Number                         #
  ##############################################################################

  test "redirect show hidden fleet numbers when appropriate" do
    verify_show_unused_or_hidden_redirects(
      show_hidden_path: show_fleet_number_path(@hidden_flight.operator.slug, @hidden_flight.fleet_number),
      redirect_path:    airlines_path
    )
  end
  
  test "redirect show fleet number for unused fleet number" do
    log_in_as(users(:user_one))
    get(show_fleet_number_path(airlines(:airline_expressjet).slug, "unused"))
    assert_redirected_to(airlines_path)
  end

  test "can see show fleet number when logged in" do
    operator     = @visible_flight.operator
    fleet_number = @visible_flight.fleet_number
    log_in_as(users(:user_one))
    get(show_fleet_number_path(operator.slug, fleet_number))
    assert_response(:success)

    check_show_airline_common(operator, :fleet_number, fleet_number: fleet_number)
  end

  test "can see show fleet number when not logged in" do
    operator     = @visible_flight.operator
    fleet_number = @visible_flight.fleet_number
    get(show_fleet_number_path(operator.slug, fleet_number))
    assert_response(:success)

    check_show_airline_common(operator, :fleet_number, fleet_number: fleet_number)
    verify_absence_of_hidden_data
  end

  ##############################################################################
  # Tests to ensure visitors can't create, update, or destroy airlines         #
  ##############################################################################

  test "visitor cannot create, update, or destroy airlines" do
    verify_create_update_destroy_redirects(
      airlines_path,
      airline_path(@visible_airline.slug)
    )
  end

  ##############################################################################
  # Tests to ensure users can't destroy airlines with flights                  #
  ##############################################################################

  test "cannot remove airline with flights" do
    log_in_as(users(:user_one))
    airline = flights(:flight_visible).airline
    
    assert_no_difference("Airline.count") do
      delete(airline_path(airline))
    end
    
    assert_redirected_to(airline_path(airline.slug))
  end

  test "cannot remove operator with flights" do
    log_in_as(users(:user_one))
    operator = flights(:flight_visible).operator
    
    assert_no_difference("Airline.count") do
      delete(airline_path(operator))
    end
    
    assert_redirected_to(airline_path(operator.slug))
  end

  test "cannot remove codeshare airline with flights" do
    log_in_as(users(:user_one))
    codeshare_airline = flights(:flight_visible).codeshare_airline
    
    assert_no_difference("Airline.count") do
      delete(airline_path(codeshare_airline))
    end
    
    assert_redirected_to(airline_path(codeshare_airline.slug))
  end

  private

  # Runs tests on a row in an airline count table
  def check_airline_flight_row(airline, expected_flight_count, error_message)
    assert_select("tr#airline-count-row-#{airline.id}", {}, error_message) do
      assert_select("a[href=?]", airline_path(id: airline.slug))
      assert_select("text.graph-value[data-value=?]", expected_flight_count.to_s, {}, "Graph bar shall have the correct flight count")
    end
  end

  # Runs tests on a row in an operator count table
  def check_operator_flight_row(operator, expected_flight_count, error_message)
    assert_select("tr#operator-count-row-#{operator.id}", {}, error_message) do
      assert_select("a[href=?]", show_operator_path(operator: operator.slug))
      assert_select("text.graph-value[data-value=?]", expected_flight_count.to_s, {}, "Graph bar shall have the correct flight count")
    end
  end

  # Runs tests common to show airline
  def check_show_airline_common(airline, type, fleet_number: nil)
    if type == :airline
      assert_select("h1", airline.name)
      assert_select("#operator-count-table")
    elsif type == :operator
      assert_select("h1", "Flights Operated by #{airline.name}")
      assert_select("#airline-count-table")
      assert_select("#fleet-number-table")
    elsif type == :fleet_number
      assert_select("h1", "#{airline.name} ##{fleet_number}")
      assert_select("a[href=?]", show_operator_path(operator: airline.slug))
      assert_select("#airline-count-table")
    end

    assert_select("#iata-code", airline.iata_code) if airline.iata_code
    assert_select("#icao-code", airline.icao_code) if airline.icao_code
    assert_select("div#map")
    assert_select(".distance-primary")

    assert_select("#aircraft-family-count-table")
    assert_select("#travel-class-count-table")
    assert_select("#superlatives-table")
    assert_select("#flight-table")
  end

end
