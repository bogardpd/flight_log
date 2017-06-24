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
  
  def first_visit(logged_in=false)
    flights = logged_in ? Flight.all : Flight.visitor
    matching_flights = flights.where("origin_airport_id = ? OR destination_airport_id = ?", self.id, self.id)
    return nil if matching_flights.length == 0
    return matching_flights.order(departure_date: :asc).first.departure_date
  end
  
  # Accepts a date range, and returns the IATA code for all airports that had
  # their first flight in this date range.
  def self.new_in_date_range(date_range, logged_in=false)
    flights = logged_in ? Flight.all : Flight.visitor
    orig = flights.joins(:origin_airport).select(:iata_code, :departure_date).group(:iata_code).minimum(:departure_date)
    dest = flights.joins(:destination_airport).select(:iata_code, :departure_date).group(:iata_code).minimum(:departure_date)
    first_flights = orig.merge(dest){|key,o,d| [o,d].min}
    return first_flights.select{|k,v| date_range.include?(v)}.map{|k,v| k}.sort
  end
  
  # Returns an array of airports, with a hash for each family containing the
  # id, airport name, IATA code, and number of visits to that airport, sorted
  # by number of visits descending.
  def self.visit_count(logged_in=false, flights: nil)
    flights ||= Flight.all
    flights = flights.visitor unless logged_in
    flights = flights.select(:trip_id, :trip_section, "origin_airports.iata_code AS origin_iata, origin_airports.city AS origin_city, origin_airports.country AS origin_country, destination_airports.iata_code AS destination_iata, destination_airports.city AS destination_city, destination_airports.country AS destination_country").joins("INNER JOIN airports AS origin_airports ON flights.origin_airport_id = origin_airports.id INNER JOIN airports AS destination_airports ON flights.destination_airport_id = destination_airports.id").order(:trip_id, :trip_section, :departure_utc)
    
    visits = Hash.new(0)
    previous_trip_section = {trip_id: nil, trip_section: nil}
    previous_destination = nil
    
    flights.each do |flight|
      current_trip_section = {trip_id: flight[:trip_id], trip_section: flight[:trip_section]
      }
      unless current_trip_section == previous_trip_section && flight[:origin_iata] == previous_destination
        # This is not a layover, so count this origin airport
        visits[[flight[:origin_iata],flight[:origin_city],flight[:origin_country]]] += 1
      end
      visits[[flight[:destination_iata],flight[:destination_city],flight[:destination_country]]] += 1
      previous_trip_section = current_trip_section
      previous_destination = flight[:destination_iata]
      
    end
    
    counts = visits.map{|k,v|
      {iata_code: k[0], city: k[1], country: k[2], visit_count: v}
    }.sort_by{|c| [-c[:visit_count] || 0, c[:city] || "", c[:iata_code] || ""]}
    
    return counts
    
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
  
  protected
  
  def strip_blanks
    STRIP_ATTRS.each { |attr| self[attr] = self[attr].strip if !self[attr].blank? }
  end
  
end
