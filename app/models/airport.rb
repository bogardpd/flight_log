# Defines a model for airports.
class Airport < ApplicationRecord
  has_many :originating_flights, :class_name => "Flight", :foreign_key => "originating_airport_id"
  has_many :arriving_flights, :class_name => "Flight", :foreign_key => "destination_airport_id"
  has_many :first_routes, :class_name => "Route", :foreign_key => "airport1_id"
  has_many :second_routes, :class_name => "Route", :foreign_key => "airport2_id"
  
  STRIP_ATTRS = %w( city country )
  CAP_CODES = %w( iata_code icao_code )
  
  before_save :capitalize_codes
  before_save :strip_blanks
  
  validates :iata_code, presence: true, length: { is: 3 }, uniqueness: { case_sensitive: false }
  validates :icao_code, presence: true, length: { is: 4 }, uniqueness: { case_sensitive: false }
  validates :city, presence: true
  validates :country, presence: true
  
  # Returns the airport's latitude and longitude in decimal degrees. If the
  # latitude and longitude aren't defined, this method attempts to look them up
  # using the FlightXML API and save them, and then returns the coordinate
  # array. If this is not successful, returns nil.
  #
  # @return [Array<Float>, nil] the latitude and longitude in decimal degrees
  def coordinates
    if self.latitude.present? && self.longitude.present?
      return [self.latitude, self.longitude]
    elsif self.icao_code.present?
      # Try to look up coordinates on FlightXML
      coordinates = FlightXML.airport_coordinates(self.icao_code)
      return nil unless coordinates.present?
      # Save coordinates to instance
      self.latitude = coordinates[0]
      self.longitude = coordinates[1]
      self.save
      return coordinates
    else
      return nil
    end
  end
  
  # Returns the image path for this airport's cropped terminal silhouette.
  # This image is always 1440px wide, and is up to 810px tall.
  #
  # @return [String] an image path
  def terminal_silhouette_path
    return "#{ExternalImage::ROOT_PATH}/projects/terminal-silhouettes/png-flight-historian/#{self.iata_code}.png"
  end
  
  # Returns the image path for this airport's uncropped terminal silhouette.
  #
  # @return [String] an image path
  def terminal_silhouette_large_path
    return "#{ExternalImage::ROOT_PATH}/projects/terminal-silhouettes/png/#{self.iata_code}.png"
  end
  
  # Accepts an airport IATA code, and returns the matching ICAO code.
  #
  # @param iata [String] the airport IATA code to look up
  # @param keep_iata [Boolean] whether or not to return the provided IATA code
  #   if an ICAO code is not found. If this is false, the method will return
  #   nil if an ICAO code is not found.
  # @return [String, nil] a matching ICAO code if found, the provided IATA code or nil if not found
  def self.convert_iata_to_icao(iata, keep_iata=true)
    airport = Airport.find_by(iata_code: iata)
    if airport.nil?
       return keep_iata ? iata : nil
    end
    icao = airport.icao_code
    return icao if icao
    return keep_iata ? iata : nil
  end
  
  # Accepts a flyer, the viewing user, and a date range, and returns the IATA
  # code for all airports that had their first flight in this date range.
  def self.new_in_date_range(flyer, current_user, date_range)
    flights = flyer.flights(current_user).reorder(nil)
    orig = flights.joins(:origin_airport).select(:iata_code, :departure_date).group(:iata_code).minimum(:departure_date)
    dest = flights.joins(:destination_airport).select(:iata_code, :departure_date).group(:iata_code).minimum(:departure_date)
    first_flights = orig.merge(dest){|key,o,d| [o,d].min}
    return first_flights.select{|k,v| date_range.include?(v)}.map{|k,v| k}.sort
  end
  
  # Returns an array of Airports, with a hash for each Airport containing the
  # id, airport name, IATA code, and number of visits to that airport, sorted
  # by number of visits descending.
  #
  # Used on various "show" views to generate a table of airports and their
  # flight counts.
  #
  # @param flights [Array<Flight>] a collection of {Flight Flights} to
  #   calculate Airport visit counts for
  # @return [Array<Hash>] details for each Airport visited
  def self.visit_count(flights)
    flights = flights.reorder(:trip_id, :trip_section, :departure_utc)
    
    visits = Hash.new(0)
    previous_trip_section = {trip_id: nil, trip_section: nil}
    previous_destination = nil
    
    flights.each do |flight|
      current_trip_section = {trip_id: flight.trip_id, trip_section: flight.trip_section
      }
      unless current_trip_section == previous_trip_section && flight.origin_airport.iata_code == previous_destination
        # This is not a layover, so count this origin airport
        visits[[flight.origin_airport.iata_code,flight.origin_airport.city,flight.origin_airport.country]] += 1
      end
      visits[[flight.destination_airport.iata_code,flight.destination_airport.city,flight.destination_airport.country]] += 1
      previous_trip_section = current_trip_section
      previous_destination = flight.destination_airport.iata_code
      
    end
    
    counts = visits.map{|k,v|
      {iata_code: k[0], city: k[1], country: k[2], visit_count: v}
    }.sort_by{|c| [-c[:visit_count] || 0, c[:city] || "", c[:iata_code] || ""]}
    
    return counts
    
  end
  
  # Take a collection of strings representing the starts of ICAO codes, and
  # return all IATA codes whose airport ICAO codes start with any of the
  # provided strings.
  # 
  # @param icao_starts [Array<String>] an array of strings of the start of
  #   ICAO codes (i.e. EG, K)
  # @return [Array<String>] ICAO codes in the region
  def self.in_region_iata_codes(icao_starts)
    return in_region_hash(icao_starts).values
  end

  # Take a collection of strings representing the starts of ICAO codes, and
  # return all airport IDs whose airport ICAO codes start with any of the
  # provided strings.
  # 
  # @param icao_starts [Array<String>] an array of strings of the start of
  #   ICAO codes (i.e. EG, K)
  # @return [Array<String>] ICAO codes in the region
  def self.in_region_ids(icao_starts)
    return in_region_hash(icao_starts).keys
  end
  
  # Take a collection of strings representing the starts of ICAO codes, and
  # return an a hash of all Airports whose airport ICAO codes start with any of
  # the provided strings.
  # 
  # Params:
  # @param icao_starts [Array<String>] an array of strings of the start of
  #   ICAO codes (i.e. EG, K)
  # @return [Hash<Integer,String>] a hash of airports with matching ICAO codes,
  #   with airport IDs as keys and IATA codes as values
  def self.in_region_hash(icao_starts)
    conditions = icao_starts.map{"icao_code LIKE ?"}.join(" OR ")
    patterns = icao_starts.map{|start| "#{start}%"}
    matching_airports = Airport.where(conditions, *patterns)
    
    iata_hash = Hash.new
    matching_airports.each{|airport| iata_hash[airport[:id]] = airport[:iata_code]}
    return iata_hash
  end
  
  # Take a collection of {Flight Flights}, and return a hash of airport IDs and
  # number of visits.
  #
  # If two flights are chronologically consecutive, the destination {Airport}
  # of the first flight is the same as the origin of the second, and these two
  # flights share the same {Trip} and trip section, then the time between the
  # two flights is a layover and only counts as one visit to shared {Airport}.
  # Otherwise, the traveler left the airport in between the flights, and it
  # counts as two separate visits to the shared {Airport}.
  #
  # @param flights [Array<Flight>] a collection of {Flight Flights}
  # @return [Hash<Integer,Integer>] a hash with airport IDs as keys and number
  #   of visits as values
  def self.frequency_hash(flights)
    airport_frequency = Hash.new(0) # All airports start with 0 flights
    previous_trip_id = nil;
    previous_trip_section = nil;
    previous_destination_airport_iata_code = nil;
    flights.includes(:origin_airport, :destination_airport).each do |flight|
      unless (flight.trip_id == previous_trip_id && flight.trip_section == previous_trip_section && flight.origin_airport.iata_code == previous_destination_airport_iata_code)
        # This is not a layover, so count this origin airport
        airport_frequency[flight.origin_airport_id] += 1
      end
      airport_frequency[flight.destination_airport_id] += 1
      previous_trip_id = flight.trip_id
      previous_trip_section = flight.trip_section
      previous_destination_airport_iata_code = flight.destination_airport.iata_code
    end
    
    return airport_frequency
    
  end
  
  protected
  
  # Removes leading and trailing whitespace from form fields before saving them
  # to the database.
  #
  # @return [Hash]
  def strip_blanks
    STRIP_ATTRS.each { |attr| self[attr] = self[attr].strip if !self[attr].blank? }
  end
  
  # Capitalizes form fields before saving them to the database.
  #
  # @return [Hash]
  def capitalize_codes
    CAP_CODES.each { |code| self[code] = self[code].upcase }
  end
  
end
