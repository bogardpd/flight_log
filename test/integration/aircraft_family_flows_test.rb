require "test_helper"

class AircraftFamilyFlowsTest < ActionDispatch::IntegrationTest
  
  def setup
    @visible_aircraft_family = aircraft_families(:aircraft_family_visible)
    @hidden_aircraft_family = aircraft_families(:aircraft_family_hidden)
    @no_flights_aircraft_family = aircraft_families(:aircraft_family_with_no_flights)
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Add/Edit Aircraft Family/Type             #
  ##############################################################################

  test "can see add aircraft family when logged in" do
    log_in_as(users(:user_one))
    get(new_aircraft_family_path)
    assert_response(:success)

    assert_select("h1", "New Aircraft Family")
    assert_select("form#new_aircraft_family")
    assert_select("input#aircraft_family_manufacturer")
    assert_select("input#aircraft_family_family_name")
    assert_select("select#aircraft_family_category")
    assert_select("input#aircraft_family_slug")
  end

  test "can see add aircraft family type when logged in" do
    parent = aircraft_families(:aircraft_737)
    log_in_as(users(:user_one))
    get(new_aircraft_family_path(family_id: parent.id))
    assert_response(:success)

    assert_select("h1", "New #{parent.family_name} Type")
    assert_select("form#new_aircraft_family")
    assert_select("input#aircraft_family_manufacturer[value=?]", parent.manufacturer)
    assert_select("input#aircraft_family_family_name")
    assert_select("input#aircraft_family_iata_aircraft_code")
    assert_select("input#aircraft_family_icao_aircraft_code")
    assert_select("select#aircraft_family_category") do
      assert_select("option[selected=selected][value=?]", parent.category)
    end
    assert_select("input#aircraft_family_slug")
    assert_select("input#aircraft_family_parent_id[value=?]", parent.id.to_s)
  end

  test "cannot see add aircraft family when not logged in" do
    get(new_aircraft_family_path)
    assert_redirected_to(root_path)    
  end

  test "cannot see add aircraft family type when not logged in" do
    parent = aircraft_families(:aircraft_737)
    get(new_aircraft_family_path(family_id: parent.id))
    assert_redirected_to(root_path)
  end

  test "can see edit aircraft family when logged in" do
    aircraft_family = aircraft_families(:aircraft_737)
    log_in_as(users(:user_one))
    get(edit_aircraft_family_path(aircraft_family))
    assert_response(:success)

    assert_select("h1", "Edit #{aircraft_family.full_name}")
    assert_select("form#edit_aircraft_family_#{aircraft_family.id}")
    assert_select("input#aircraft_family_manufacturer[value=?]", aircraft_family.manufacturer)
    assert_select("input#aircraft_family_family_name[value=?]", aircraft_family.family_name)
    assert_select("select#aircraft_family_category") do
      assert_select("option[selected=selected][value=?]", aircraft_family.category)
    end
    assert_select("input#aircraft_family_slug[value=?]", aircraft_family.slug)
  end

  test "can see edit aircraft family type when logged in" do
    aircraft_type = aircraft_families(:aircraft_737_800)
    log_in_as(users(:user_one))
    get(edit_aircraft_family_path(aircraft_type))
    assert_response(:success)

    assert_select("h1", "Edit #{aircraft_type.full_name}")
    assert_select("form#edit_aircraft_family_#{aircraft_type.id}")
    assert_select("input#aircraft_family_manufacturer[value=?]", aircraft_type.manufacturer)
    assert_select("input#aircraft_family_family_name[value=?]", aircraft_type.family_name)
    assert_select("input#aircraft_family_iata_aircraft_code[value=?]", aircraft_type.iata_aircraft_code)
    assert_select("input#aircraft_family_icao_aircraft_code[value=?]", aircraft_type.icao_aircraft_code)
    assert_select("select#aircraft_family_category") do
      assert_select("option[selected=selected][value=?]", aircraft_type.category)
    end
    assert_select("input#aircraft_family_slug[value=?]", aircraft_type.slug)
  end

  test "cannot see edit aircraft family when not logged in" do
    aircraft_family = aircraft_families(:aircraft_737)
    get(edit_aircraft_family_path(aircraft_family))
    assert_redirected_to(root_path)
  end

  test "cannot see edit aircraft family type when not logged in" do
    aircraft_type = aircraft_families(:aircraft_737_800)
    get(edit_aircraft_family_path(aircraft_type))
    assert_redirected_to(root_path)
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Index Aircraft Families                   #
  ##############################################################################

  test "can see index aircraft families when logged in" do
    aircraft = AircraftFamily.flight_table_data(logged_in_flights).select{|aircraft| aircraft[:id].present? && aircraft[:flight_count] > 0}
    log_in_as(users(:user_one))
    get(aircraft_families_path)
    assert_response(:success)

    assert_select("h1", "Aircraft Families")
    assert_select("table#aircraft-family-count-table") do
      check_flight_row(@visible_aircraft_family, aircraft.find{|a| a[:id] == @visible_aircraft_family.id}[:flight_count], "This view shall show aircraft with visible flights")
      check_flight_row(@hidden_aircraft_family, aircraft.find{|a| a[:id] == @hidden_aircraft_family.id}[:flight_count], "This view shall show aircraft with only hidden flights when logged in")
      assert_select("td#aircraft-family-count-total", {text: /^#{aircraft.size} aircraft famil(y|(ies))/}, "Ranked tables shall have a total row with a correct total")
    end
    assert_select("table#aircraft-families-with-no-flights-table", {}, "This view shall show an aircraft families with no flights table when logged in") do
      assert_select("tr#aircraft-family-with-no-flights-row-#{@no_flights_aircraft_family.id}")
    end

    assert_select("div#admin-actions", {}, "This view shall show admin actions when logged in") do
      assert_select("a[href=?]", new_aircraft_family_path, {}, "This view shall show a New Aircraft Family link when logged in")
    end

  end

  test "can see index aircraft families when not logged in" do
    aircraft = AircraftFamily.flight_table_data(visitor_flights).select{|aircraft| aircraft[:id].present? && aircraft[:flight_count] > 0}
    get(aircraft_families_path)
    assert_response(:success)

    assert_select("h1", "Aircraft Families")
    assert_select("table#aircraft-family-count-table") do
      check_flight_row(@visible_aircraft_family, aircraft.find{|a| a[:id] == @visible_aircraft_family.id}[:flight_count], "This view shall show aircraft with visible flights")
      assert_select("tr#aircraft-family-count-table-#{@hidden_aircraft_family.id}", {count: 0}, "This view shall not show aircraft with only hidden flights when not logged in")
      assert_select("td#aircraft-family-count-total", {text: /^#{aircraft.size} aircraft famil(y|(ies))/}, "Ranked tables shall have a total row with a correct total")
    end

    assert_select("table#aircraft-families-with-no-flights-table", {count: 0}, "This view shall not show an aircraft families with no flights table when not logged in")
    assert_select("div#admin-actions", {count: 0}, "This view shall not show admin actions when not logged in")
    assert_select("a[href=?]", new_aircraft_family_path, {count: 0}, "This view shall not show a New Aircraft Family link when not logged in")
  end

  private

  # Runs tests on a row in a aircraft count table
  def check_flight_row(aircraft_family, expected_flight_count, error_message)
    assert_select("tr#aircraft-family-count-row-#{aircraft_family.id}", {}, error_message) do
      assert_select("a[href=?]", aircraft_family_path(id: aircraft_family.slug))
      assert_select("text.graph-value", expected_flight_count.to_s, "Graph bar shall have the correct flight count")
    end
  end

end
