require "application_system_test_case"

class FlightsTest < ApplicationSystemTestCase
  # All tests to ensure visitors can't view hidden, create, update, or destroy
  # flights are located in INTEGRATION tests.

  def setup
    stub_flight_xml_get_wsdl
    stub_flight_xml_post_airport_info(airports(:airport_with_no_coordinates).icao_code, {})
    stub_gcmap_get_map
    @trip = trips(:trip_hidden)
    @pass = pk_passes(:pk_pass_existing_data)

    # Parameters for FlightAware FlightXML lookup tests:
    @fa_flight = Hash.new
    @fa_flight[:ident]              = "AAL2300" # From bcbp.txt
    @fa_flight[:flight_number]      = "2300"    # From bcbp.txt
    @fa_flight[:origin]             = "KDFW"    # From bcbp.txt
    @fa_flight[:destination]        = "KORD"    # From bcbp.txt
    @fa_flight[:airline_name]       = airlines(:airline_american).name # Matches bcbp.txt
    @fa_flight[:aircraft_icao_code] = aircraft_families(:aircraft_a321).icao_code
    @fa_flight[:departure_time]     = @pass.departure_utc.to_i
    @fa_flight[:fa_flight_id]       = "#{@fa_flight[:ident]}-#{@fa_flight[:departure_time].to_i}-airline-0001"
  end

  test "creating, updating, and destroying a flight" do

    flight = {
      origin_airport:      airports(:airport_ord),
      destination_airport: airports(:airport_dfw),
      trip_section:        1,
      departure_date:      Date.parse("2020-01-01"),
      departure_utc:       Time.parse("2020-01-01 12:00"),
      airline:             airlines(:airline_american),
      airline_update:      airlines(:airline_united),
      travel_class:        "business"
    }

    system_log_in_as(users(:user_one))

    # Create flight:
    assert_difference("Flight.count", 1) do
      visit(trip_path(@trip))
      click_on("Add Flight")
      click_on("Create a new flight")

      fill_in("Trip Section", with: flight[:trip_section])
      select(flight[:origin_airport].iata_code, from: :flight_origin_airport_id)
      select(flight[:destination_airport].iata_code, from: :flight_destination_airport_id)
      select(flight[:airline].name, from: :flight_airline_id)
      select(TravelClass::name_and_description(flight[:travel_class]), from: :flight_travel_class)
      select_datetime(flight[:departure_date], "flight_departure_date", include_time: false)
      select_datetime(flight[:departure_utc], "flight_departure_utc", include_time: true)

      click_on("Add Flight")
    end    

    # Update flight:
    assert_no_difference("Flight.count") do
      visit(flight_path(Flight.last))
      click_on("Edit Flight")

      select(flight[:airline_update].name, from: :flight_airline_id)
      click_on("Update Flight")

      assert_equal(flight[:airline_update], Flight.last.airline)
    end

    # Destroy flight:
    assert_difference("Flight.count", -1) do
      visit(flight_path(Flight.last))
      accept_confirm do
        click_on("Delete Flight")
      end

      # Give the delete enough time to go through:
      visit(flights_path)
    end

  end

  test "creating a flight from a pkpass" do

    stub_flight_xml_post_flight_info_ex(@fa_flight[:fa_flight_id], {aircrafttype: @fa_flight[:aircraft_icao_code]})
    stub_flight_xml_post_get_flight_id(@fa_flight[:ident], @fa_flight[:departure_time], @fa_flight[:fa_flight_id])
    stub_flight_xml_airline_flight_info(@fa_flight[:fa_flight_id], {})
    
    system_log_in_as(users(:user_one))

    assert_difference("Flight.count", 1) do
      visit(trip_path(@trip))
      within("#message-boarding-passes-available-for-import") do
        click_on("import")
      end
      within("#create-pk-pass-row-#{@pass.id}") do
        click_on("Create this flight")
      end
      click_on("Add Flight")

      new_flight = Flight.last
      assert_equal(@fa_flight[:flight_number], new_flight.flight_number)
      assert_equal(@fa_flight[:aircraft_icao_code], new_flight.aircraft_family.icao_code)
    end
  end

  test "creating a flight from a pkpass with nil date" do
    pass = pk_passes(:pk_pass_nil_date)
    flight = Hash.new
    flight[:flight_number] = "1621"    # From pass fixture
    flight[:ident]         = "AAL1621" # From pass fixture
    flight[:fa_flight_id]  = "AAL1621-1575870329-airline-0404"
    flight[:origin]        = "KORD"    # From pass fixture
    flight[:destination]   = "KDFW"    # From pass fixture

    stub_flight_xml_post_flight_info_ex(flight[:ident], {faFlightID: flight[:fa_flight_id]})
    stub_flight_xml_post_airport_info(airports(:airport_ord).icao_code, {})
    stub_flight_xml_post_airport_info(airports(:airport_dfw).icao_code, {})
    stub_flight_xml_post_flight_info_ex(flight[:fa_flight_id], {})
    stub_flight_xml_airline_flight_info(flight[:fa_flight_id], {})
    
    system_log_in_as(users(:user_one))

    assert_difference("Flight.count", 1) do
      visit(trip_path(@trip))
      within("#message-boarding-passes-available-for-import") do
        click_on("import")
      end
      within("#create-pk-pass-row-#{pass.id}") do
        click_on("Create this flight")
      end
      within("#select-flight-row-#{flight[:fa_flight_id]}") do
        click_on("Select")
      end
      click_on("Add Flight")

      new_flight = Flight.last
      assert_equal(flight[:flight_number], new_flight.flight_number)
    end
  end

  test "creating a flight from BCBP data" do
    
    stub_flight_xml_post_flight_info_ex(@fa_flight[:ident], {faFlightID: @fa_flight[:fa_flight_id], origin: @fa_flight[:origin], destination: @fa_flight[:destination]})
    stub_flight_xml_post_flight_info_ex(@fa_flight[:fa_flight_id], {aircrafttype: @fa_flight[:aircraft_icao_code]})
    stub_flight_xml_post_get_flight_id(@fa_flight[:ident], @fa_flight[:departure_time], @fa_flight[:fa_flight_id])
    stub_flight_xml_post_airport_info(@fa_flight[:origin], {})
    stub_flight_xml_post_airport_info(@fa_flight[:destination], {})
    stub_flight_xml_airline_flight_info(@fa_flight[:fa_flight_id], {})
    
    system_log_in_as(users(:user_one))

    assert_difference("Flight.count", 1) do
      visit(trip_path(@trip))
      within("#message-boarding-passes-available-for-import") do
        click_on("import")
      end
      
      fill_in("Use a barcode scanner", with: file_fixture("bcbp.txt").read)
      click_on("Submit barcode data")
      within("#select-flight-row-#{@fa_flight[:fa_flight_id]}") do
        click_on("Select")
      end
      click_on("Add Flight")

      new_flight = Flight.last
      assert_equal(@fa_flight[:flight_number], new_flight.flight_number)
      assert_equal(@fa_flight[:aircraft_icao_code], new_flight.aircraft_family.icao_code)

    end
  end

  test "creating a flight from airline and flight number" do
    stub_flight_xml_post_flight_info_ex(@fa_flight[:ident], {faFlightID: @fa_flight[:fa_flight_id]})
    stub_flight_xml_post_flight_info_ex(@fa_flight[:fa_flight_id], {aircrafttype: @fa_flight[:aircraft_icao_code]})
    stub_flight_xml_post_airport_info(@fa_flight[:origin], {})
    stub_flight_xml_post_airport_info(@fa_flight[:destination], {})
    stub_flight_xml_airline_flight_info(@fa_flight[:fa_flight_id], {})

    system_log_in_as(users(:user_one))

    assert_difference("Flight.count", 1) do
      visit(trip_path(@trip))
      within("#message-boarding-passes-available-for-import") do
        click_on("import")
      end

      select(@fa_flight[:airline_name], from: :airline_icao)
      fill_in("flight_number", with: @fa_flight[:flight_number])
      click_on("Search")
      within("#select-flight-row-#{@fa_flight[:fa_flight_id]}") do
        click_on("Select")
      end
      click_on("Add Flight")

      new_flight = Flight.last
      assert_equal(@fa_flight[:flight_number], new_flight.flight_number)
      assert_equal(@fa_flight[:aircraft_icao_code], new_flight.aircraft_family.icao_code)

    end

  end

  test "creating a flight with unknown FlightXML ICAO codes" do
    unknown_aircraft = {icao: "A322", iata: "322", manufacturer: "Airbus", type: "A322", category: "Narrow-body", slug: "Airbus-A322"}
    unknown_airline = {icao: "AAA", iata: "A2", name: "American Airline Association", slug: "American-Airline-Association"}
    unknown_airport = {icao: "ZZZZ", iata: "ZZZ", city: "Zizzville", country: "Zazz", slug: "ZZZ"}
    stub_flight_xml_post_flight_info_ex(@fa_flight[:ident], {faFlightID: @fa_flight[:fa_flight_id]})
    stub_flight_xml_post_flight_info_ex(@fa_flight[:fa_flight_id], {aircrafttype: unknown_aircraft[:icao], ident: unknown_airline[:icao] + "1111", origin: unknown_airport[:icao]})
    stub_flight_xml_post_airport_info(unknown_airport[:icao], {})
    stub_flight_xml_post_airport_info(@fa_flight[:origin], {})    
    stub_flight_xml_post_airport_info(@fa_flight[:destination], {})    
    stub_flight_xml_airline_flight_info(@fa_flight[:fa_flight_id], {})

    system_log_in_as(users(:user_one))

    assert_difference("Flight.count", 1) do
      visit(trip_path(@trip))
      within("#message-boarding-passes-available-for-import") do
        click_on("import")
      end

      select(@fa_flight[:airline_name], from: :airline_icao)
      fill_in("flight_number", with: @fa_flight[:flight_number])
      click_on("Search")
      within("#select-flight-row-#{@fa_flight[:fa_flight_id]}") do
        click_on("Select")
      end

      assert_difference("Airport.count", 1) do
        # New airport form
        fill_in("IATA Code", with: unknown_airport[:iata])
        fill_in("City", with: unknown_airport[:city])
        fill_in("Country", with: unknown_airport[:country])
        fill_in("Slug", with: unknown_airport[:slug])
        click_on("Continue")
      end
      
      assert_difference("AircraftFamily.count", 1) do
        # New aircraft form
        fill_in("Manufacturer", with: unknown_aircraft[:manufacturer])
        fill_in("Type Name", with: unknown_aircraft[:type])
        fill_in("IATA Code", with: unknown_aircraft[:iata])
        fill_in("Unique Slug", with: unknown_aircraft[:slug])
        select(unknown_aircraft[:category], from: :aircraft_family_category)
        click_on("Continue")
      end

      assert_difference("Airline.count", 1) do
        # New airline form
        fill_in("Name", with: unknown_airline[:name])
        fill_in("IATA Code", with: unknown_airline[:iata])
        fill_in("Unique Slug", with: unknown_airline[:slug])
        click_on("Continue")
      end

      click_on("Add Flight")
    end
  end

  test "creating a flight with departure date and UTC datetime being more than 48 hours apart" do
    current_date = Time.parse("2020-01-01 00:00:00")
    future_date = current_date + 3.days

    flight = {
      origin_airport:      airports(:airport_ord),
      destination_airport: airports(:airport_dfw),
      trip_section:        1,
      airline:             airlines(:airline_american),
    }

    system_log_in_as(users(:user_one))

    assert_difference("Flight.count", 1) do
      visit(trip_path(@trip))
      click_on("Add Flight")
      click_on("Create a new flight")

      fill_in("Trip Section", with: flight[:trip_section])
      select(flight[:origin_airport].iata_code, from: :flight_origin_airport_id)
      select(flight[:destination_airport].iata_code, from: :flight_destination_airport_id)
      select(flight[:airline].name, from: :flight_airline_id)
      select_datetime(current_date, "flight_departure_date", include_time: false)
      select_datetime(future_date, "flight_departure_utc", include_time: true)
      
      click_on("Add Flight")
    end

    assert_css("div.message-warning", text: Flight::WARNING_DEPARTURE_DATE_DEPARTURE_UTC_TOO_FAR)

  end
  
  private

  def select_datetime(datetime, form_field_name, include_time: true) 
    date_format = ["%Y", "%B", "%-d"]
    date_format.push("%H", "%M") if include_time
    date_format.each_with_index do |d, i|
      select(datetime.strftime(d), from: "#{form_field_name}_#{i+1}i")
    end
  end
end
