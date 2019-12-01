ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)
require "rails/test_help"
require "webmock/minitest"
require "minitest/reporters"
Minitest::Reporters.use!
WebMock.disable_net_connect!(allow_localhost: true)

class ActiveSupport::TestCase
  
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all
  set_fixture_class(pk_passes: PKPass)
  
  # Sets up stub requests used by multiple tests
  def stub_common_requests
    stub_request(:get, /www.gcmap.com/).to_return(status: 200, body: "", headers: {})
    stub_request(:head, /amazonaws.com\/pbogardcom-images/).to_return(status: 200, body: "", headers: {})

    stub_request(:get, "https://flightxml.flightaware.com/soap/FlightXML2/wsdl").
      with(
        headers: {
        'Accept'=>'*/*',
        'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Authorization'=>/Basic \w*==/,
        'User-Agent'=>'Ruby'
        }).
      to_return(status: 200, body: "", headers: {})
  end

  # Logs in a test user (integration tests)
  def log_in_as(user)
    cookies[:remember_token] = user.remember_token
  end

  # Logs in a test user (system tests)
  def system_log_in_as(user)
    visit(login_path)
    fill_in("Username", with: user.name)
    fill_in("Password", with: "password")
    click_on("Log in")
  end

  # Logs out a test user
  def log_out
    cookies[:remember_token] = nil
  end

  # Returns all flights
  def logged_in_flights
    return users(:user_one).flights(users(:user_one))
  end
  
  # Returns non-hidden flights
  def visitor_flights
    return users(:user_one).flights(nil)
  end

  # Checks that admin actions are present and contain links to specific paths.
  def verify_presence_of_admin_actions(*paths_to_check)
    assert_select("div#admin-actions", {}, "This view shall show admin actions when logged in") do
      paths_to_check.each do |path|
        if path == :delete
          # Delete doesn't have a path, so we just have to pass it in as a
          # symbol. We need to actually check for Delete text so we don't
          # accidentally pick up log out links.
          assert_select("a[data-method=delete]", {text: /^Delete/}, "This view shall show a delete link when logged in")
        else
          assert_select("a[href=?]", path, {}, "This view shall show a link to #{path} when logged in")
        end
      end
    end
  end

  # Checks that no admin actions are present.
  def verify_absence_of_admin_actions(*paths_to_check)
    assert_select("div#admin-actions", {count: 0}, "This view shall not show admin actions when not logged in")
    paths_to_check.each do |path|
      if path == :delete
        # Delete doesn't have a path, so we just have to pass it in as a symbol.
        assert_select("a[data-method=delete]", {text: /^Delete/, count: 0}, "This view shall not show a delete link when not logged in")
      else
        assert_select("a[href=?]", path, {count: 0}, "This view shall not show a link to #{path} when not logged in")
      end
    end
  end

  # Checks that no models with only hidden flights are present.
  def verify_absence_of_hidden_data
    hidden_flight = flights(:flight_hidden)
   
    # Count tables:
    assert_select("tr#aircraft-family-count-row-#{hidden_flight.aircraft_family.id}", {count: 0}, "This view shall not show aircraft with only hidden flights when not logged in")
    assert_select("tr#airline-count-row-#{hidden_flight.airline.id}", {count: 0}, "This view shall not show airlines with only hidden flights when not logged in")
    assert_select("tr#airport-count-row-#{hidden_flight.origin_airport.id}", {count: 0}, "This view shall not show airports with only hidden flights when not logged in")    
    assert_select("tr#operator-count-row-#{hidden_flight.operator.id}", {count: 0}, "This view shall not show operators with only hidden flights when not logged in")
    assert_select("tr#route-count-row-#{[hidden_flight.origin_airport.slug,hidden_flight.destination_airport.slug].sort.join("-to-")}", {count: 0}, "This view shall not show routes with only hidden flights when not logged in")
    assert_select("tr#tail-number-count-row-#{hidden_flight.tail_number}", {count: 0}, "This view shall not show tail numbers with only hidden flights when not logged in")
    assert_select("tr#travel-class-count-row-#{hidden_flight.travel_class}", {count: 0}, "This view shall not show classes with only hidden flights when not logged in")

    # Other tables:
    assert_select("tr#flight-row-#{hidden_flight.id}", {count: 0}, "This view shall not show hidden flights when not logged in")
    assert_select("tr#trip-row-#{hidden_flight.trip.id}", {count: 0}, "This view shall not show hidden trips when not logged in")
    assert_select("tr#superlative-row-#{[hidden_flight.origin_airport.slug,hidden_flight.destination_airport.slug].sort.join("-to-")}", {count: 0}, "This view shall not show superlative routes with only hidden flights when not logged in")

    

  end

  # Checks that no 'X with No Flights' tables are present
  def verify_absence_of_no_flights_tables
    assert_select("table[id$=?]", "-with-no-flights-table", {count: 0}, "This view shall not show a no flights table when not logged in")
  end

  # Checks that show pages for unused or hidden entities are shown when logged
  # in, and redirected to an index when not logged in.
  def verify_show_unused_or_hidden_redirects(show_unused_path: nil, show_hidden_path: nil, redirect_path: root_path)
    if show_unused_path
      get(show_unused_path)
      assert_redirected_to(redirect_path)
    end

    if show_hidden_path
      get(show_hidden_path)
      assert_redirected_to(redirect_path)
    end

    log_in_as(users(:user_one))

    if show_unused_path
      get(show_unused_path)
      assert_response(:success)
      verify_presence_of_admin_actions(:delete)
    end

    if show_hidden_path
      get(show_hidden_path)
      assert_response(:success)
    end
  end

  # Checks that create, update, and destroy actions are redirected to home when
  # not logged in.
  def verify_create_update_destroy_redirects(new_path, update_destroy_path)
    post(new_path)
    assert_redirected_to(root_path)

    put(update_destroy_path)
    assert_redirected_to(root_path)

    delete(update_destroy_path)
    assert_redirected_to(root_path)
  end

end