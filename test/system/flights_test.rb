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
    @fa_flight[:ident]              = "AAL1734" # From bcbp.txt
    @fa_flight[:flight_number]      = "1734"    # From bcbp.txt
    @fa_flight[:origin]             = "KDFW"    # From bcbp.txt
    @fa_flight[:destination]        = "KORD"    # From bcbp.txt
    @fa_flight[:departure_time]     = Time.parse(JSON.parse(@pass.pass_json)["expirationDate"])
    @fa_flight[:fa_flight_id]       = "#{@fa_flight[:ident]}-#{@fa_flight[:departure_time].to_i}-airline-0001"
    @fa_flight[:icao_aircraft_code] = aircraft_families(:aircraft_737_800).icao_aircraft_code
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
      select(flight[:airline].airline_name, from: :flight_airline_id)
      select(TravelClass::name_and_description(flight[:travel_class]), from: :flight_travel_class)
      select_datetime(flight[:departure_date], "flight_departure_date", include_time: false)
      select_datetime(flight[:departure_utc], "flight_departure_utc", include_time: true)

      click_on("Add Flight")
    end    

    # Update flight:
    assert_no_difference("Flight.count") do
      visit(flight_path(Flight.last))
      click_on("Edit Flight")

      select(flight[:airline_update].airline_name, from: :flight_airline_id)
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

    stub_flight_xml_post_flight_info_ex(@fa_flight[:fa_flight_id], {})
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
      assert_equal(@fa_flight[:icao_aircraft_code], new_flight.aircraft_family.icao_aircraft_code)
    end
  end

  test "creating a flight from BCBP data" do
    
    stub_flight_xml_post_flight_info_ex(@fa_flight[:ident], {fa_flight_id: @fa_flight[:fa_flight_id], origin: @fa_flight[:origin], destination: @fa_flight[:destination], aircraft_family: @fa_flight[:icao_aircraft_code]})
    stub_flight_xml_post_flight_info_ex(@fa_flight[:fa_flight_id], {})
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
      click_on("Select")
      click_on("Add Flight")

      new_flight = Flight.last
      assert_equal(@fa_flight[:flight_number], new_flight.flight_number)
      assert_equal(@fa_flight[:icao_aircraft_code], new_flight.aircraft_family.icao_aircraft_code)

    end
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
