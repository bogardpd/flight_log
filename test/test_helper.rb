ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)
require "rails/test_help"
require "minitest/reporters"
Minitest::Reporters.use!

class ActiveSupport::TestCase
  
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all
  set_fixture_class(pk_passes: PKPass)
  
  # Logs in a test user
  def log_in_as(user)
    cookies[:remember_token] = user.remember_token
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
        assert_select("a[href=?]", path, {}, "This view shall show a link to #{path} when logged in")
      end
    end
  end

  # Checks that no admin actions are present.
  def verify_absence_of_admin_actions(*paths_to_check)
    assert_select("div#admin-actions", {count: 0}, "This view shall not show admin actions when not logged in")
    paths_to_check.each do |path|
      assert_select("a[href=?]", path, {count: 0}, "This view shall not show a link to #{path} when not logged in")
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

end