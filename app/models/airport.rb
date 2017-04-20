class Airport < ApplicationRecord
  has_many :originating_flights, :class_name => 'Flight', :foreign_key => 'originating_airport_id'
  has_many :arriving_flights, :class_name => 'Flight', :foreign_key => 'destination_airport_id'
  has_many :first_routes, :class_name => 'Route', :foreign_key => 'airport1_id'
  has_many :second_routes, :class_name => 'Route', :foreign_key => 'airport2_id'
  
  STRIP_ATTRS = %w( city country )
  
  before_save { |airport| airport.iata_code = iata_code.upcase }
  before_save :strip_blanks
  
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
  
  
  
  def country_flag_path
    if self.country == nil
      "flags/unknown-country.png"
    else
      image_location = "flags/" + self.country.downcase.gsub(/\s+/, '-').gsub(/[^a-z0-9_-]/, '').squeeze('-') + ".png"
      if Rails.application.assets.find_asset(image_location)
        image_location
      else
        "flags/unknown-country.png"
      end
    end
  end
  
  # Take a collection of flights and a region, and return a hash of all
  # of the flights' airports that are within the given reason, with Airport
  # IDs as the keys and IATA codes as the values.
  # Params:
  # +flights+:: A collection of Flights.
  # +region+:: Only returns airports from this region.
  def self.region_iata_codes(flights, region)
    
    # Create array of all flights' airport IDs:
    airport_ids = Array.new
    flights.each do |flight|
      airport_ids.push(flight[:origin_airport_id])
      airport_ids.push(flight[:destination_airport_id])
    end
    airport_ids.uniq!.sort!
    
    # Filter out non-CONUS airports, if necessary:
    if region == :conus
      airport_ids &= Airport.where(region_conus: true).pluck(:id)
    end
    
    # Get IATA codes:
    iata_hash = Hash.new
    airports = Airport.find(airport_ids)
    airports.each do |airport|
      iata_hash[airport[:id]] = airport[:iata_code]
    end
    
    return iata_hash
  end
  
  # Take a collection of flights, and return a hash of with airport IDs as the
  # keys and the number of visits to each airport as the values.
  # Params:
  # +flights+:: A collection of Flights, with flights_table applied.
  def self.frequency_hash(flights)
    airport_frequency = Hash.new(0) # All airports start with 0 flights
    previous_trip_id = nil;
    previous_trip_section = nil;
    previous_destination_airport_iata_code = nil;
    flights.each do |flight|
      unless (flight.trip_id == previous_trip_id && flight.trip_section == previous_trip_section && flight.origin_iata_code == previous_destination_airport_iata_code)
        # This is not a layover, so count this origin airport
        airport_frequency[flight.origin_airport_id] += 1
      end
      airport_frequency[flight.destination_airport_id] += 1
      previous_trip_id = flight.trip_id
      previous_trip_section = flight.trip_section
      previous_destination_airport_iata_code = flight.destination_iata_code
    end
    
    return airport_frequency
    
  end
  
  # Take a collection of flights, and return an array of hashes of airport IDs,
  # IATA codes, cities, countries, and visit frequencies.
  # Params:
  # +flights+:: A collection of Flights, with flights_table applied. 
  def self.airport_table(flights)
    airport_frequency = Airport.frequency_hash(flights)
    airports = Airport.find(airport_frequency.keys)
    airport_table = Array.new
    airports.each do |airport|
      airport_table.push({:id => airport.id, :iata_code => airport.iata_code, :city => airport.city, :country => airport.country, :frequency => airport_frequency[airport.id]})
    end
    airport_table.sort_by! { |airport| [-airport[:frequency], airport[:city]] }
    return airport_table
  end
  
  protected
  
  def strip_blanks
    STRIP_ATTRS.each { |attr| self[attr] = self[attr].strip if !self[attr].blank? }
  end
  
end
