require "test_helper"

class AircraftFamilyFlowsTest < ActionDispatch::IntegrationTest

  include ActionView::Helpers::NumberHelper
  
  def setup
    stub_aws_head_images
    
    @visible_aircraft_family = aircraft_families(:aircraft_family_visible)
    @hidden_aircraft_family = aircraft_families(:aircraft_family_hidden)
    @no_flights_aircraft_family = aircraft_families(:aircraft_family_no_flights)
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
  # Tests for aircraft_family_count_table partial                              #
  ##############################################################################

  test "can see index aircraft families when logged in" do
    aircraft = AircraftFamily.flight_table_data(logged_in_flights).select{|aircraft| aircraft[:id].present? && aircraft[:flight_count] > 0}
    log_in_as(users(:user_one))
    get(aircraft_families_path)
    assert_response(:success)

    verify_presence_of_admin_actions(new_aircraft_family_path)

    assert_select("h1", "Aircraft Families")

    assert_select("table#aircraft-family-count-table") do
      check_flight_row(@visible_aircraft_family, aircraft.find{|a| a[:id] == @visible_aircraft_family.id}[:flight_count], "This view shall show aircraft with visible flights")
      check_flight_row(@hidden_aircraft_family, aircraft.find{|a| a[:id] == @hidden_aircraft_family.id}[:flight_count], "This view shall show aircraft with only hidden flights when logged in")
      assert_select("td#aircraft-family-count-total", {text: /^#{number_with_delimiter(aircraft.size)} aircraft famil(y|(ies))/}, "Ranked tables shall have a total row with a correct total")
    end

    assert_select("table#aircraft-families-with-no-flights-table", {}, "This view shall show an aircraft families with no flights table when logged in") do
      assert_select("tr#aircraft-family-with-no-flights-row-#{@no_flights_aircraft_family.id}")
    end  
    
  end

  test "can see index aircraft families when not logged in" do
    get(aircraft_families_path)
    assert_response(:success)
    verify_absence_of_hidden_data
    verify_absence_of_admin_actions(new_aircraft_family_path)
    verify_absence_of_no_flights_tables
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Show Aircraft                             #
  # Tests for aircraft_child_types partial                                     #
  # Tests for aircraft_illustration partial                                    #
  ##############################################################################

  test "redirect show unused or hidden airports when appropriate" do
    verify_show_unused_or_hidden_redirects(
      show_unused_path: aircraft_family_path(aircraft_families(:aircraft_type_no_flights).slug),
      show_hidden_path: aircraft_family_path(aircraft_families(:aircraft_type_hidden).slug),
      redirect_path:    aircraft_families_path
    )
  end

  test "show aircraft delete link is not present when family with no flights has child types" do
    log_in_as(users(:user_one))
    get(aircraft_family_path(aircraft_families(:aircraft_family_no_flights).slug))
    assert_response(:success)
    assert_select("a[data-method=delete]", {text: /^Delete/, count: 0}, "This view shall not show a delete link when aircraft has child types")
  end

  test "can see show aircraft with family when logged in" do
    aircraft_family = aircraft_families(:aircraft_737)
    log_in_as(users(:user_one))
    get(aircraft_family_path(aircraft_family.slug))
    assert_response(:success)

    check_show_aircraft_common(aircraft_family)
    verify_presence_of_admin_actions(edit_aircraft_family_path(aircraft_family))
  end

  test "can see show aircraft with family when not logged in" do
    aircraft_family = aircraft_families(:aircraft_737)
    get(aircraft_family_path(aircraft_family.slug))
    assert_response(:success)

    check_show_aircraft_common(aircraft_family)
    verify_absence_of_hidden_data
    verify_absence_of_admin_actions(edit_aircraft_family_path(aircraft_family))
  end

  test "can see show aircraft with type when logged in" do
    aircraft_type = aircraft_families(:aircraft_737_800)
    log_in_as(users(:user_one))
    get(aircraft_family_path(aircraft_type.slug))
    assert_response(:success)

    check_show_aircraft_common(aircraft_type)
    verify_presence_of_admin_actions(edit_aircraft_family_path(aircraft_type))
  end

  test "can see show aircraft with type when not logged in" do
    aircraft_type = aircraft_families(:aircraft_737_800)
    get(aircraft_family_path(aircraft_type.slug))
    assert_response(:success)
    
    check_show_aircraft_common(aircraft_type)
    verify_absence_of_hidden_data
    verify_absence_of_admin_actions(edit_aircraft_family_path(aircraft_type))
  end

  ##############################################################################
  # Tests to ensure visitors can't create, update, or destroy aircraft         #
  ##############################################################################

  test "visitor cannot create, update, or destroy aircraft" do
    verify_create_update_destroy_redirects(
      aircraft_families_path,
      aircraft_family_path(@visible_aircraft_family.slug)
    )
  end

  private

  # Runs tests on a row in a aircraft count table
  def check_flight_row(aircraft_family, expected_flight_count, error_message)
    assert_select("tr#aircraft-family-count-row-#{aircraft_family.id}", {}, error_message) do
      assert_select("a[href=?]", aircraft_family_path(id: aircraft_family.slug))
      assert_select("text.graph-value", number_with_delimiter(expected_flight_count.to_s, delimiter: ","), "Graph bar shall have the correct flight count")
    end
  end

  # Runs tests common to show aircraft family and show aircraft type
  def check_show_aircraft_common(aircraft)
    assert_select("h1", aircraft.full_name)
    assert_select("#iata-aircraft-code", aircraft.iata_aircraft_code) if aircraft.iata_aircraft_code
    assert_select("#icao-aircraft-code", aircraft.icao_aircraft_code) if aircraft.icao_aircraft_code
    assert_select("#aircraft-illustration")
    assert_select("div#map")
    assert_select(".distance-primary")

    assert_select("table#aircraft-subtype-table") if aircraft.children.any?

    assert_select("#airline-count-table")
    assert_select("#operator-count-table")
    assert_select("#travel-class-count-table")
    assert_select("#superlatives-table")
    assert_select("#flight-table")
  end

end
