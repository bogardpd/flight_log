# Controls administrative pages. Users must be logged in to view any of these pages.

class AdminController < ApplicationController
  before_action :logged_in_user
  
  # Shows the administrative main menu.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def admin
  end
  
  # Shows a table of the total count of business, mixed, and personal {Flight Flights}
  # for each calendar year.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def annual_flight_summary
    @flight_summary = Flight.by_year
    @distance_summary = Flight.by_year(distances: true)
  end
  
  # Shows the boarding pass data of all {Flight Flights} with invalid boarding pass
  # data.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def boarding_pass_validator
    @pass_flights = Flight.select(:id, :boarding_pass_data).where("boarding_pass_data IS NOT NULL").order(:departure_utc)
  end

  # Shows an ordered list of the first time each airport was visited.
  # 
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def airport_first_visits
    flights = Flight.chronological.includes(:airline, :origin_airport, :destination_airport)
    @airports = Airport.all.pluck(:id, :iata_code, :slug).map{|a| [a[0], {
      iata_code: a[1],
      slug: a[2],
    }]}.to_h
    @airport_first_visits = Hash.new()
    flights.each do |flight|
      unless @airport_first_visits.has_key?(flight.origin_airport_id)
        @airport_first_visits[flight.origin_airport_id] = flight
      end
      unless @airport_first_visits.has_key?(flight.destination_airport_id)
        @airport_first_visits[flight.destination_airport_id] = flight
      end
    end
  end
  
end
