require "test_helper"

class AircraftFamilyFlowsTest < ActionDispatch::IntegrationTest

  def setup
    stub_aws_s3_head

    @visible_aircraft_family = aircraft_families(:aircraft_family_visible)
    @hidden_aircraft_family = aircraft_families(:aircraft_family_hidden)
    @no_flights_aircraft_family = aircraft_families(:aircraft_family_no_flights)

    @family_params_new = {
      manufacturer: "Embraer",
      name:         "ERJ-145 Family",
      category:     "regional_jet",
      slug:         "Embraer-ERJ-145-Family",
    }
    @family_params_update = {
      name:         "737F Family",
    }
    @type_params_new = {
      manufacturer: "Embraer",
      name:         "ERJ-145",
      iata_code:    "ER4",
      icao_code:    "E145",
      category:     "regional_jet",
      slug:         "Embraer-ERJ-145"
    }
    @type_params_update = {
      name:         "737-800F",
    }

    @extension_types = {
      'geojson' => "application/geo+json",
      'gpx'     => "application/gpx+xml",
      'graphml' => "application/xml",
      'kml'     => "application/vnd.google-earth.kml+xml",
    }
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
    assert_select("input#aircraft_family_name")
    assert_select("select#aircraft_family_category")
    assert_select("input#aircraft_family_slug")
  end

  test "can see add aircraft family type when logged in" do
    parent = aircraft_families(:aircraft_737)
    log_in_as(users(:user_one))
    get(new_aircraft_family_path(family_id: parent.id))
    assert_response(:success)

    assert_select("h1", "New #{parent.name} Type")
    assert_select("form#new_aircraft_family")
    assert_select("input#aircraft_family_manufacturer[value=?]", parent.manufacturer)
    assert_select("input#aircraft_family_name")
    assert_select("input#aircraft_family_iata_code")
    assert_select("input#aircraft_family_icao_code")
    assert_select("select#aircraft_family_category") do
      assert_select("option[selected=selected][value=?]", parent.category)
    end
    assert_select("input#aircraft_family_slug")
    assert_select("input#aircraft_family_parent_id[value=?]", parent.id.to_s)
  end

  test "cannot see add aircraft family when not logged in" do
    get(new_aircraft_family_path)
    assert_redirected_to(login_path)
  end

  test "cannot see add aircraft family type when not logged in" do
    parent = aircraft_families(:aircraft_737)
    get(new_aircraft_family_path(family_id: parent.id))
    assert_redirected_to(login_path)
  end

  test "can create aircraft family and type when logged in" do
    log_in_as(users(:user_one))
    assert_difference("AircraftFamily.count", 1) do
      post(aircraft_families_path, params: {aircraft_family: @family_params_new})
    end
    family = AircraftFamily.find_by(slug: @family_params_new[:slug])
    assert_redirected_to(aircraft_family_path(family.slug))
    assert_equal(@family_params_new[:manufacturer], family.manufacturer)
    assert_equal(@family_params_new[:name], family.name)
    assert_equal(@family_params_new[:category], family.category)
    assert_equal(@family_params_new[:slug], family.slug)

    type_params = @type_params_new.merge(parent_id: family.id)
    assert_difference("AircraftFamily.count", 1) do
      post(aircraft_families_path, params: {aircraft_family: type_params})
    end
    type = AircraftFamily.find_by(slug: @type_params_new[:slug])
    assert_redirected_to(aircraft_family_path(type.slug))
    assert_equal(@type_params_new[:name], type.name)
    assert_equal(@type_params_new[:iata_code], type.iata_code)
    assert_equal(@type_params_new[:icao_code], type.icao_code)
    assert_equal(@type_params_new[:slug], type.slug)
  end

  test "cannot create aircraft family or type when not logged in" do
    assert_no_difference("AircraftFamily.count") do
      post(aircraft_families_path, params: {aircraft_family: @family_params_new})
    end
    assert_redirected_to(login_path)

    assert_no_difference("AircraftFamily.count") do
      post(aircraft_families_path, params: {aircraft_family: @type_params_new})
    end
    assert_redirected_to(login_path)
  end

  test "can see edit aircraft family when logged in" do
    aircraft_family = aircraft_families(:aircraft_737)
    log_in_as(users(:user_one))
    get(edit_aircraft_family_path(aircraft_family))
    assert_response(:success)

    assert_select("h1", "Edit #{aircraft_family.full_name}")
    assert_select("form#edit_aircraft_family_#{aircraft_family.id}")
    assert_select("input#aircraft_family_manufacturer[value=?]", aircraft_family.manufacturer)
    assert_select("input#aircraft_family_name[value=?]", aircraft_family.name)
    assert_select("input#aircraft_family_iata_code[value=?]", aircraft_family.iata_code)
    assert_select("input#aircraft_family_icao_code", {count: 0})
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
    assert_select("input#aircraft_family_name[value=?]", aircraft_type.name)
    assert_select("input#aircraft_family_iata_code[value=?]", aircraft_type.iata_code)
    assert_select("input#aircraft_family_icao_code[value=?]", aircraft_type.icao_code)
    assert_select("select#aircraft_family_category") do
      assert_select("option[selected=selected][value=?]", aircraft_type.category)
    end
    assert_select("input#aircraft_family_slug[value=?]", aircraft_type.slug)
  end

  test "cannot see edit aircraft family when not logged in" do
    aircraft_family = aircraft_families(:aircraft_737)
    get(edit_aircraft_family_path(aircraft_family))
    assert_redirected_to(login_path)
  end

  test "cannot see edit aircraft family type when not logged in" do
    aircraft_type = aircraft_families(:aircraft_737_800)
    get(edit_aircraft_family_path(aircraft_type))
    assert_redirected_to(login_path)
  end

  test "can update aircraft family when logged in" do
    log_in_as(users(:user_one))

    aircraft_family = aircraft_families(:aircraft_737)
    patch(aircraft_family_path(aircraft_family), params: {aircraft_family: @family_params_update})
    assert_redirected_to(aircraft_family_path(aircraft_family.slug))
    aircraft_family.reload
    assert_equal(@family_params_update[:name], AircraftFamily.find(aircraft_family.id).name)
  end

  test "can update aircraft type when logged in" do
    log_in_as(users(:user_one))

    aircraft_type = aircraft_families(:aircraft_737_800)
    patch(aircraft_family_path(aircraft_type), params: {aircraft_family: @type_params_update})
    assert_redirected_to(aircraft_family_path(aircraft_type.slug))
    aircraft_type.reload
    assert_equal(@type_params_update[:name], AircraftFamily.find(aircraft_type.id).name)
  end

  test "cannot update aircraft family when not logged in" do
    aircraft_family = aircraft_families(:aircraft_737)
    original_name = aircraft_family.name
    patch(aircraft_family_path(aircraft_family), params: {aircraft_family: @family_params_update})
    assert_redirected_to(login_path)
    aircraft_family.reload
    assert_equal(original_name, aircraft_family.name)
  end

  test "cannot update aircraft type when not logged in" do
    aircraft_type = aircraft_families(:aircraft_737_800)
    original_name = aircraft_type.name
    patch(aircraft_family_path(aircraft_type), params: {aircraft_family: @type_params_update})
    assert_redirected_to(login_path)
    aircraft_type.reload
    assert_equal(original_name, aircraft_type.name)
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
      assert_select("td#aircraft-family-count-total[data-total=?]", aircraft.size.to_s, {}, "Ranked tables shall have a total row with a correct total")
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
    stub_aws_s3_get_timeout

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

  test "can see show aircraft alternate map formats" do
    aircraft_type = aircraft_families(:aircraft_737_800)
    @extension_types.each do |extension, type|
      get(aircraft_family_path(aircraft_type.slug, map_id: "aircraft_family_map", extension: extension))
      assert_response(:success)
      assert_equal(type, response.media_type)
    end
  end

  ##############################################################################
  # Tests for deleting aircraft families and types                             #
  ##############################################################################

  test "can remove aircraft family and type when logged in" do
    log_in_as(users(:user_one))

    # Delete child type first.
    type = aircraft_families(:aircraft_type_no_flights)
    assert_difference("AircraftFamily.count", -1) do
      delete(aircraft_family_path(type))
    end
    assert_redirected_to(aircraft_family_path(type.parent.slug))

    # Delete family.
    family = aircraft_families(:aircraft_family_no_flights)
    assert_difference("AircraftFamily.count", -1) do
      delete(aircraft_family_path(family))
    end
    assert_redirected_to(aircraft_families_path)

  end

  test "cannot remove aircraft family when not logged in" do
    aircraft = aircraft_families(:aircraft_family_no_flights_no_children)
    assert_no_difference("AircraftFamily.count") do
      delete(aircraft_family_path(aircraft))
    end
    assert_redirected_to(login_path)
  end

  test "cannot remove aircraft type when not logged in" do
    aircraft = aircraft_families(:aircraft_type_no_flights)
    assert_no_difference("AircraftFamily.count") do
      delete(aircraft_family_path(aircraft))
    end
    assert_redirected_to(login_path)
  end

  test "cannot remove aircraft family with flights" do
    log_in_as(users(:user_one))
    aircraft = flights(:flight_visible).aircraft_family

    assert_no_difference("AircraftFamily.count") do
      delete(aircraft_family_path(aircraft))
    end

    assert_redirected_to(aircraft_family_path(aircraft.slug))
  end

  test "cannot remove aircraft family with child types" do
    log_in_as(users(:user_one))
    aircraft = aircraft_families(:aircraft_family_no_flights)

    assert_no_difference("AircraftFamily.count") do
      delete(aircraft_family_path(aircraft))
    end

    assert_redirected_to(aircraft_family_path(aircraft.slug))
  end

  private

  # Runs tests on a row in a aircraft count table
  def check_flight_row(aircraft_family, expected_flight_count, error_message)
    assert_select("tr#aircraft-family-count-row-#{aircraft_family.id}", {}, error_message) do
      assert_select("a[href=?]", aircraft_family_path(id: aircraft_family.slug))
      assert_select("text.graph-value[data-value=?]", expected_flight_count.to_s, {}, "Graph bar shall have the correct flight count")
    end
  end

  # Runs tests common to show aircraft family and show aircraft type
  def check_show_aircraft_common(aircraft)
    assert_select("h1", aircraft.full_name)
    assert_select("#aircraft-illustration")
    assert_select("div#aircraft_family_map")
    assert_select(".distance-mi")

    assert_select("table#aircraft-subtype-table") if aircraft.children.any?

    assert_select("#airline-count-table")
    assert_select("#operator-count-table")
    assert_select("#travel-class-count-table")
    assert_select("#superlatives-table")
    assert_select("#flight-table")
  end

end
