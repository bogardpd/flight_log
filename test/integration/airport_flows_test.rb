require "test_helper"

class AirportFlowsTest < ActionDispatch::IntegrationTest
  
  test "can see add airport when logged in" do
    log_in_as users(:user_one)
    get "/airports/new"
    assert :success
    assert_select "h1", "New Airport"
    assert_select "form#new_airport"
    assert_select "input#airport_iata_code"
    assert_select "input#airport_icao_code"
    assert_select "input#airport_city"
    assert_select "input#airport_country"
    assert_select "input#airport_slug"
  end

  test "cannot see add airport when not logged in" do
    get "/airports/new"
    assert_redirected_to "/"
  end

  test "can see edit airport when logged in" do

  end

  test "cannot see edit airport when not logged in" do

  end

end
