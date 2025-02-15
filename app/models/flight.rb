# Defines a model for flights.
class Flight < ApplicationRecord
  belongs_to :trip
  belongs_to :origin_airport, :class_name => "Airport"
  belongs_to :destination_airport, :class_name => "Airport"
  belongs_to :airline
  belongs_to :aircraft_family, :optional => true
  belongs_to :operator, :class_name => "Airline", :optional => true
  belongs_to :codeshare_airline, :class_name => "Airline", :optional => true
  
  # Form fields which should be saved as nil when the field is blank.
  NULL_ATTRS = %w( flight_number aircraft_name tail_number travel_class comment fleet_number boarding_pass_data )
  # Form fields which should be saved with leading and trailing whitespace
  # removed.
  STRIP_ATTRS = %w( operator fleet_number aircraft_family aircraft_name tail_number )
  # Form fields which should be saved capitalized and with all non-alphanumeric
  # characters removed.
  SIMPLIFY_ATTRS = %w( tail_number )

  # Warning text for if departure date and departure UTC might be too far apart
  WARNING_DEPARTURE_DATE_DEPARTURE_UTC_TOO_FAR = ActionController::Base.helpers.sanitize("Your departure date and UTC time are more than a day apart &ndash; are you sure they&rsquo;re correct?")
  
  before_save :nil_if_blank
  before_save :strip_blanks
  before_save :simplify_tail
  
  validates :origin_airport_id, :presence => true
  validates :destination_airport_id, :presence => true
  validates :trip_id, :presence => true
  validates :trip_section, :presence => true
  validates :departure_date, :presence => true
  validates :departure_utc, :presence => true
  validates :airline_id, presence: true
  validates :travel_class, :inclusion => { in: TravelClass::CLASSES.keys, message: "%{value} is not a valid travel class" }, :allow_nil => true, :allow_blank => true
  
  # Sorts Flights chronologically.
  # @method chronological()
  # @scope instance
  # @return [Array<Flight>] Flights sorted by departure time (UTC)
  scope :chronological, -> {
    order(:departure_utc)
  }


  # Returns the {AircraftFamily} parent family for the Flight, and the
  # {AircraftFamily} child type for the Flight if available.
  #
  # @return [Hash<Symbol, AircraftFamily>] a hash containing the
  #   {AircraftFamily} parent family for the Flight, and the {AircraftFamily}
  #   child type for the Flight if available.
  def aircraft_family_and_type
    return nil unless aircraft_family
    return {family: aircraft_family} if aircraft_family.is_root_family?
    return {family: aircraft_family.parent, type: aircraft_family}
  end

  # Returns the {Airline} and flight number for the Flight.
  #
  # @return [String] the airline and flight number
  def name
    return self.airline.name + " " + self.flight_number.to_s
  end

  # For a given flight collection, returns business, mixed, personal, and
  # undefined Flight counts grouped by year. Years with no flights that are
  # between the earliest and latest flight will be included, with zeroes in the
  # values.
  #
  # @param distances [Boolean] If set to true, values will be distances in
  #   miles. Otherwise, values will be counts of flights.
  # @return [Hash<Number,Hash>] a hash with years as the keys, and
  #   hashes of counts of business, mixed, personal, and undefined flights as
  #   the values
  # @example
  #   Flight.by_year #=> {2009: {business: 35, mixed: 4, personal: 7, undefined: 0}}
  def self.by_year(distances: false)
    # Create hash ranging from earliest to latest years (default all values to zero):
    summary = Hash.new
    if self.year_range
      self.year_range.each do |year|
        summary[year] = {business: 0, mixed: 0, personal: 0, undefined: 0}
      end
    end

    if distances
      route_distances = self.route_distances
      flights = self.select("departure_date, origin_airport_id, destination_airport_id, trips.purpose AS purpose")
    else
      flights = self.select("departure_date, trips.purpose AS purpose")
    end
    flights = flights.joins("LEFT OUTER JOIN trips ON trips.id = flights.trip_id")
    
    # Loop through all flights (with year and flight.trip.purpose selected and increment hash):
    flights.each do |flight|
      purpose = flight.purpose.present? ? flight.purpose.to_sym : :undefined
      if distances
        summary[flight.departure_date.year][purpose] += route_distances[[flight.origin_airport_id,flight.destination_airport_id].sort]
      else
        summary[flight.departure_date.year][purpose] += 1
      end
    end
    
    return summary
  end

  # Returns an array of FlightAware flight IDs for a Flight. If the Flight has
  # no FlightAware ID, returns an empty array.
  #
  # @return [Array<String>] an array of FlightAware flight IDs
  def fa_flight_ids_array
    return [] if self.fa_flight_id.blank?
    return self.fa_flight_id.split(",")
  end

  # Returns a hash of routes for a collection of flights with sorted pairs of
  # {Airport} IDs as keys and distances in miles as values.
  #
  # @scope instance
  # @return [Hash] A hash in the format [Integer airport_id, Integer airport_id] => Integer distance in miles
  def route_distances
    return self.class.route_distances
  end

  # Returns a hash of routes for a collection of flights with sorted pairs of
  # {Airport} IDs as keys and distances in miles as values.
  #
  # @scope instance
  # @return [Hash] A hash in the format [Integer airport_id, Integer airport_id] => Integer distance in miles
  def self.route_distances
    airport_ids = self.all.pluck(:origin_airport_id, :destination_airport_id).flatten.uniq
    
    routes = Route.where("airport1_id IN (:a_ids) OR airport2_id IN (:a_ids)", a_ids: airport_ids)   # Trying to select only the specific routes used creates stack depth issues, so this method compromises by selecting all routes which involve any of the Airports in any of the Flights.
    distances = routes.map{|r| [[r.airport1_id,r.airport2_id].sort, r.distance_mi]}.to_h

    return self.all.pluck(:origin_airport_id, :destination_airport_id).map{|pair| [pair.sort, distances[pair.sort]]}.to_h
  end

  # Return the longest and shortest flights from a collection of flights.
  #
  # Returns a hash with keys of :max, :min, and :zero, which contain the longest
  # Flight(s), shortest non-zero-length Flight(s), and zero-length Flight(s)
  # respectively. Each of these values is itself a hash, with an array of two
  # {Airport Airports} as each key, and the distance in statute miles as each
  # value.
  # 
  # Zero-length flights are strictly defined as flights where the origin and
  # destination airports are the same. Theoretically, if a flight were flown
  # between two airports that were less than 0.5 miles apart, then the flight
  # would be included in :min rather than :zero, even though its integer
  # distance would be rounded to zero.
  #
  # @scope instance
  # @return [Hash] A hash of superlative routes.
  # @example
  #   Flight.all.superlatives #=> {
  #     :max => {[Airport1,Airport2] => 8500},
  #     :min => {[Airport3,Airport4] => 50, [Airport5,Airport6] => 50},
  #     :zero => {[Airport7,Airport7] => 0}
  #   }
  def self.superlatives
    route_distances = self.all.route_distances
    
    # Separate out routes where both airports are the same:
    routes_zero, routes_non_zero = route_distances.partition{|k, v| k[0] == k[1]}
    routes_non_zero = routes_non_zero.to_h
    routes_zero = routes_zero.to_h

    distance_min, distance_max = routes_non_zero.values.compact.sort.values_at(0,-1)

    route_superlatives = Hash.new
    route_superlatives[:max] = routes_non_zero.select{|k, v| v == distance_max}
    route_superlatives[:min] = routes_non_zero.select{|k, v| v == distance_min}
    route_superlatives[:zero] = routes_zero

    # Convert airport IDs to airports:
    airport_ids = route_superlatives.values.map{|r| r.keys}.flatten.uniq
    airports = Airport.find(airport_ids).map{|a| [a.id, a]}.to_h
    
    return route_superlatives.map{|k,v| [k, v.map{|r| [[airports[r[0][0]], airports[r[0][1]]], r[1]] }.to_h ]}.to_h
  end

  # Returns the total distance in statute miles of a collection of Flights.
  # 
  # @scope instance
  # @param allow_unknown_distances [Boolean] If set to true, will consider
  #   Flights with unknown distances to have zero distance. If set to false,
  #   will return nil if any of the Flight distances are unknown.
  # @return [Integer, nil] the total distance of the Flights in statute miles
  def self.total_distance(allow_unknown_distances=true)
    route_distances = self.all.route_distances
    distances = self.all.pluck(:origin_airport_id, :destination_airport_id).map{|pair| route_distances[pair.sort]}
    if allow_unknown_distances || (distances.include?(nil) == false)
      return distances.reduce(0){|sum, d| sum + (d || 0)}
    else
      return nil
    end
  end

  # For a given flight collection, returns a range of the years that contain
  # flights.
  # 
  # @return [Range<Integer>] a range of years
  def self.year_range
    return nil unless self.any?
    sorted = self.chronological
    return sorted.first.departure_date.year..sorted.last.departure_date.year
  end

  # For a given flight collection, returns all years that have at least one
  # Flight.
  #
  # @return [Array<Integer>] the years having at least one Flight
  def self.years_with_flights
    flights = self.chronological
    years_with_flights = Array.new
    flights.each do |flight|
      years_with_flights.push(flight.departure_date.year)
    end
    return years_with_flights.uniq
  end
    
  protected
  
  # Converts blank form fields to nil before saving them to the database.
  #
  # @return [Hash]
  def nil_if_blank
    NULL_ATTRS.each { |attr| self[attr] = nil if self[attr].blank? }
  end

  # Removes leading and trailing whitespace from form fields before saving them
  # to the database.
  #
  # @return [Hash]
  def strip_blanks
    STRIP_ATTRS.each { |attr| self[attr] = self[attr].strip if !self[attr].blank? }
  end
  
  # Capitalizes and removes non-alphanumeric characters from form fields before
  # saving them to the database.
  #
  # @return [Hash]
  def simplify_tail
    SIMPLIFY_ATTRS.each { |attr| self[attr] = TailNumber.simplify(self[attr]) if !self[attr].blank? }
  end
  
end
