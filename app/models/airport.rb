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
  validates :city, :presence => true
  validates :country, :presence => true
  
  def country_flag_path
    if self.country == nil
      "flags/unknown-country.png"
    else
      image_location = "flags/" + self.country.downcase.gsub(/\s+/, "-").gsub(/[^a-z0-9_-]/, "").squeeze("-") + ".png"
      if Rails.application.assets.find_asset(image_location)
        image_location
      else
        "flags/unknown-country.png"
      end
    end
  end
  
  # Accepts an IATA code, and attempts to look up the ICAO code. If it does not
  # find an ICAO code and keep_iata is true, it returns the provided IATA code.
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
  
  # Returns an array of airports, with a hash for each family containing the
  # id, airport name, IATA code, and number of visits to that airport, sorted
  # by number of visits descending.
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
  # return an array of IATA codes in the region.
  # Params:
  # +icao_starts+:: An array of strings of the start of ICAO codes (i.e. EG, K)
  def self.in_region(icao_starts)
    return in_region_hash(icao_starts).values
  end
  
  # Take a collection of strings representing the starts of ICAO codes, and
  # return an a hash of airports in the region, with airport ids as keys and
  # IATA codes as values.
  # Params:
  # +icao_starts+:: An array of strings of the start of ICAO codes (i.e. EG, K)
  def self.in_region_hash(icao_starts)
    conditions = icao_starts.map{"icao_code LIKE ?"}.join(" OR ")
    patterns = icao_starts.map{|start| "#{start}%"}
    matching_airports = Airport.where(conditions, *patterns)
    
    iata_hash = Hash.new
    matching_airports.each{|airport| iata_hash[airport[:id]] = airport[:iata_code]}
    return iata_hash
  end
  
  # Take a collection of flights, and return a hash of with airport IDs as the
  # keys and the number of visits to each airport as the values.
  # Params:
  # +flights+:: A collection of Flights.
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
  
  def strip_blanks
    STRIP_ATTRS.each { |attr| self[attr] = self[attr].strip if !self[attr].blank? }
  end
  
  def capitalize_codes
    CAP_CODES.each { |code| self[code] = self[code].upcase }
  end
  
end
