class Airport < ActiveRecord::Base
  has_many :originating_flights, :class_name => 'Flight', :foreign_key => 'originating_airport_id'
  has_many :arriving_flights, :class_name => 'Flight', :foreign_key => 'destination_airport_id'
  has_many :first_routes, :class_name => 'Route', :foreign_key => 'airport1_id'
  has_many :second_routes, :class_name => 'Route', :foreign_key => 'airport2_id'
  
  before_save { |airport| airport.iata_code = iata_code.upcase }
  
  validates :iata_code, :presence => true, :length => { :is => 3 }, :uniqueness => { :case_sensitive => false }
  validates :city, :presence => true
  validates :country, :presence => true
  
  def all_flights(logged_in)
    # Returns a collection of Flights that have this airport as an origin or destination.
    if logged_in
      flights = Flight.chronological.where("origin_airport_id = :airport_id OR destination_airport_id = :airport_id", {:airport_id => self})
    else
      flights = Flight.visitor.chronological.where("origin_airport_id = :airport_id OR destination_airport_id = :airport_id", {:airport_id => self})
    end
    return flights
  end
  
  def airline_frequency(logged_in)
    # Returns a hash of the airlines of the flights using this airport, and how many flights involving this airport each airline has.
    flights = self.all_flights(logged_in)
    airline_frequency_hash = Hash.new(0) # All airlines start with 0 flights
    flights.each do |flight|
      airline_frequency_hash[flight.airline] += 1
    end
    return airline_frequency_hash
  end
  
  def aircraft_frequency(logged_in)
      # Returns a hash of the aircraft families of the flights using this airport, and how many flights involving this airport each aircraft family has.
      flights = self.all_flights(logged_in).where('aircraft_family IS NOT NULL')
      aircraft_frequency_hash = Hash.new(0) # All aircraft families start with 0 flights
      flights.each do |flight|
        aircraft_frequency_hash[flight.aircraft_family] += 1
      end
      return aircraft_frequency_hash
  end
  
  def country_flag_path
    if self.country == nil
      "flight_log/flags/unknown-country.png"
    else
      image_location = "flight_log/flags/" + self.country.downcase.gsub(/\s+/, '-').gsub(/[^a-z0-9_-]/, '').squeeze('-') + ".png"
      if Rails.application.assets.find_asset(image_location)
        image_location
      else
        "flight_log/flags/unknown-country.png"
      end
    end
  end
  
  def self.frequency_array(flight_array)
    flight_array = flight_array.chronological
    airport_frequency = Hash.new(0) # All airports start with 0 flights
    @airport_array = Array.new
    @airport_conus_array = Array.new
    previous_trip_id = nil;
    previous_trip_section = nil;
    previous_destination_airport_iata_code = nil;
    flight_array.each do |flight|
      unless (flight.trip.id == previous_trip_id && flight.trip_section == previous_trip_section && flight.origin_airport.iata_code == previous_destination_airport_iata_code)
        # This is not a layover, so count this origin airport
        airport_frequency[flight.origin_airport_id] += 1
      end
      airport_frequency[flight.destination_airport_id] += 1
      previous_trip_id = flight.trip.id
      previous_trip_section = flight.trip_section
      previous_destination_airport_iata_code = flight.destination_airport.iata_code
    end
    #return airport_frequency
    
    airports = Airport.find(airport_frequency.keys)
    airport_array = Array.new
    airports.each do |airport|
      # Create world airport array:
      airport_array.push({:id => airport.id, :iata_code => airport.iata_code, :city => airport.city, :country => airport.country, :frequency => airport_frequency[airport.id]})
    end
    airport_array = airport_array.sort_by { |airport| [-airport[:frequency], airport[:city]] }
    return airport_array
  end
  
end
