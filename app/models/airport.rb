# Defines a model for airports.
class Airport < ApplicationRecord
  has_many :originating_flights, :class_name => "Flight", :foreign_key => "originating_airport_id"
  has_many :arriving_flights, :class_name => "Flight", :foreign_key => "destination_airport_id"
  has_many :first_routes, :class_name => "Route", :foreign_key => "airport1_id"
  has_many :second_routes, :class_name => "Route", :foreign_key => "airport2_id"
  
  # Form fields which should be saved with leading and trailing whitespace
  # removed.
  STRIP_ATTRS = %w( city country )
  # Form fields which should be saved capitalized.
  CAP_CODES = %w( iata_code icao_code )
  
  before_save :capitalize_codes
  before_save :strip_blanks
  
  validates :iata_code, presence: true, length: { is: 3 }, uniqueness: { case_sensitive: false }
  validates :icao_code, presence: true, length: { is: 4 }, uniqueness: { case_sensitive: false }
  validates :slug, presence: true, uniqueness: { case_sensitive: false }
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
  
  # Given two IDs, returns the one that is not associated with this {Airport}.
  # If both are associated with this airport (a flight where the origin and
  # destination are the same) then this airport's ID will be returned. If
  # neither are associated with this airport, nil will be returned.
  #
  # Used by {direct_flight_count} to determine which airport on a direct
  # {Flight} is the remote airport.
  #
  # @param id_1 [Integer] an {Airport} ID
  # @param id_2 [Integer] an {Airport} ID
  # @return [Integer, nil] the remote {Airport} ID
  def remote_airport(id_1, id_2)
    return nil unless [id_1, id_2].include?(self.id)
    return self.id == id_1 ? id_2 : id_1
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
  
  # Given a collection of flights and a direct flight {Airport}, returns data
  # about the direct flights to or from the specified airport within the flight
  # collection. Returns an array with a hash for each remote airport, with each
  # hash containing the airport name, IATA code, country, distance in miles to
  # the direct flight airport, and count of direct flights to or from the
  # direct flight airport.
  #
  # Used on {AirportsController#show} to generate the Direct Flight Airports
  # table.
  #
  # @param flights [Array<Flight>] a collection of {Flight Flights} to
  #   calculate direct flights within
  # @param direct_flight_airport [Airport] the airport to calculate direct
  #   flights from and to
  # @param sort_category [:city, :code, :distance, :flights] the category to
  #   sort the array by
  # @param sort_direction [:asc, :desc] the direction to sort the array
  #
  # @return [Array<Hash>] details for each {Airport} with direct flights to
  #   the +direct_flight_airport+
  #
  # @example
  #   Airport.direct_flight_count(Flight.all, Airport.find(1)) #=> [
  #     {:iata_code=>"ORD", :city=>"Chicago (O’Hare)", :country=>"United States", :distance_mi=>801, :total_flights=>6},
  #     {:iata_code=>"SLC", :city=>"Salt Lake City", :country=>"United States", :distance_mi=>987, :total_flights=>6},
  #     {:iata_code=>"SEA", :city=>"Seattle/Tacoma", :country=>"United States", :distance_mi=>1658, :total_flights=>4}
  #   ]
  def self.direct_flight_count(flights, direct_flight_airport, sort_category=nil, sort_direction=nil)
    
    # Filter flights to only flights involving the direct_flight_airport:
    flights = flights.to_a.select{|f| f[:origin_airport_id] == direct_flight_airport.id || f[:destination_airport_id] == direct_flight_airport.id}
    
    # Calculate direct flight counts by airport id:
    count_by_id = Hash.new(0)
    flights.each do |flight|
      count_by_id[direct_flight_airport.remote_airport(flight[:origin_airport_id], flight[:destination_airport_id])] += 1
    end

    # Calculate flight distances by remote airport id:
    distance_by_id = Hash.new
    routes = Route.where(airport1_id: count_by_id.keys, airport2_id: direct_flight_airport.id).or(Route.where(airport1_id: direct_flight_airport.id, airport2_id: count_by_id.keys)).pluck(:airport1_id,:airport2_id,:distance_mi)
    routes.each do |route|
      distance_by_id[direct_flight_airport.remote_airport(route[0], route[1])] = route[2]
    end

    # Fill in airport details:
    airports = Airport.find(count_by_id.keys).pluck(:id, :iata_code, :city, :country)
    airports.map!{|a| {iata_code: a[1], city: a[2], country: a[3], distance_mi: distance_by_id[a[0]], total_flights: count_by_id[a[0]]}}

    # Sort array:
    sort_mult = (sort_direction == :asc ? 1 : -1)
    case sort_category
    when :city
      airports.sort_by!{|airport| airport[:city]}
      airports.reverse! if sort_direction == :desc
    when :code
      airports.sort_by!{|airport| airport[:iata_code]}
      airports.reverse! if sort_direction == :desc
    when :flights
      airports.sort_by!{|airport| [sort_mult*airport[:total_flights],airport[:city]]}
    when :distance
      airports.sort_by!{|airport| [sort_mult*airport[:distance_mi],airport[:city]]}
    else
      airports.sort_by!{|airport| [-airport[:total_flights],airport[:city]]}
    end

    return airports
  end

  # Returns an array of airports, with a hash for each airport containing the
  # id, airport name, IATA code, and number of visits to that airport, sorted
  # by number of visits descending.
  #
  # Used on various "show" views to generate a table of airports and their
  # flight counts.
  #
  # If only a hash of visit counts is needed, {visit_frequencies} should be
  # used instead.
  #
  # @param flights [Array<Flight>] a collection of {Flight Flights} to
  #   calculate Airport visit counts for
  # @param sort_category [:country, :city, :code, :visits] the category to sort
  #   the array by
  # @param sort_direectionection [:asc, :desc] the direction to sort the array
  # @return [Array<Hash>] details for each Airport visited
  def self.visit_table_data(flights, sort_category=nil, sort_direectionection=nil)
    flights = flights.includes(:origin_airport, :destination_airport).reorder(:trip_id, :trip_section, :departure_utc)
    
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
    }

    case sort_category
    when :country
      if sort_direectionection == :asc
        counts.sort_by!{|airport| [airport[:country], airport[:city]]}
      else
        counts.sort!{|a, b| [b[:country], a[:city]] <=> [a[:country], b[:city]] }
      end
    when :city
      counts.sort_by!{|airport| airport[:city]}
      counts.reverse! if sort_direectionection == :desc
    when :code
      counts.sort_by!{|airport| airport[:iata_code]}
      counts.reverse! if sort_direectionection == :desc
    when :visits
      sort_mult = (sort_direectionection == :desc ? -1 : 1)
      counts.sort_by!{ |airport| [sort_mult*airport[:visit_count], airport[:city]] }
    else    
      counts.sort_by!{|airport| [-airport[:visit_count] || 0, airport[:city] || "", airport[:iata_code] || ""]}
    end
    
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
    return in_region_hash(icao_starts).airports
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
  #   with airport IDs as keys and IATA codes as airports
  def self.in_region_hash(icao_starts)
    conditions = icao_starts.map{"icao_code LIKE ?"}.join(" OR ")
    patterns = icao_starts.map{|start| "#{start}%"}
    matching_airports = Airport.where(conditions, *patterns)
    
    iata_hash = Hash.new
    matching_airports.each{|airport| iata_hash[airport[:id]] = airport[:iata_code]}
    return iata_hash
  end
  
  # Take a collection of {Flight Flights}, and return a hash of airport IDs and
  # number of visits. Used when only a quick lookup of visits is needed; if an
  # array of data about each airport is needed, {visit_table_data} should be used
  # instead.
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
  #   of visits as airports
  def self.visit_frequencies(flights)
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
