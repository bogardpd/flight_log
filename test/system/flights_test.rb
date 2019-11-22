require "application_system_test_case"

class FlightsTest < ApplicationSystemTestCase
  # All tests to ensure visitors can't view hidden, create, update, or destroy
  # flights are located in INTEGRATION tests.

  def setup
    @trip = trips(:trip_hidden)
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
    pk_pass = pk_passes(:pk_pass_existing_data)
    system_log_in_as(users(:user_one))

    assert_difference("Flight.count", 1) do
      visit(trip_path(@trip))
      within("#message-boarding-passes-available-for-import") do
        click_on("import")
      end
      within("#create-pk-pass-row-#{pk_pass.id}") do
        click_on("Create this flight")
      end
      click_on("Add Flight")
    end
  end

  test "creating a flight from BCBP data" do
    pass_data = "M1BOGARD/PAUL D       EABCDEF DFWORDAA 1734 115G010C0088 148>218 MM    BAA              29001001123456732AA AA XXXXXXX              cK2fOqmxzIOQtY8kTP+pZq4x6jSEpSNo|AP/5vWrpbl7jfI68vaOHQEMFnrEGFNrQgw=="
    system_log_in_as(users(:user_one))

    assert_difference("Flight.count", 1) do
      visit(trip_path(@trip))
      within("#message-boarding-passes-available-for-import") do
        click_on("import")
      end
      
      fill_in("Use a barcode scanner", with: pass_data)
      click_on("Submit barcode data")

      click_on("Add Flight")
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
