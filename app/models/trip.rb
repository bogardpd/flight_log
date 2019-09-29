# Defines a model for trips.
# 
# Within the {Flight} model, a {Flight} contains both a reference to a Trip ID
# and an integer trip section number. Trip sections are used to distinguish
# between layovers and multiple visits to a given airport within a given Trip,
# in the situation where two {Flight Flights} are chronologically consecutive
# and the destination {Airport} of the first {Flight} is the same as the origin
# of the second. If these two flights share the same Trip ID and trip section,
# then the time between the two {Flight Flights} is a layover and only counts
# as one visit to shared {Airport}. Otherwise, the traveler left the airport in
# between the {Flight Flights}, and it counts as two separate visits to the
# shared {Airport}.
#
# Trips can be marked as hidden, which means they (and their {Flight Flights})
# will not be included in views and flight data for anybody other than the
# {User} who they belong to.
class Trip < ApplicationRecord
  has_many :flights, dependent: :destroy
  belongs_to :user
  
  validates :user_id, presence: true
  validates :name, presence: true

  # Valid trip purposes.
  PURPOSES = {"business" => "Business",
              "mixed"    => "Mixed",
              "personal" => "Personal"}

  # HTML to use to indicate a trip is hidden, or a flight is part of a hidden trip.
  HIDDEN_MARKER = ActionController::Base.helpers.content_tag(:div, "Hidden", class: "hidden-marker")

  # Form fields which should be saved as nil when the field is blank.
  NULL_ATTRS = %w( comment )
  before_save :nil_if_blank
    
  # Takes a flight departure time, and returns the trip section this {Flight}
  # most likely belongs to. Used while prepopulating the {FlightsController#new
  # new Flight} form to guess whether a new {Flight} is more likely to be part
  # of the previous flight's trip section or a new trip section.
  # 
  # @param departure_utc [DateTime] the UTC departure time of the new {Flight}
  # @return [Integer] the most likely trip section for this new flight
  def estimated_trip_section(departure_utc)
    flights = self.flights.chronological
    if flights.any?
      last_flight = self.flights.chronological.last
      if departure_utc && departure_utc >= last_flight.departure_utc + 1.day
        return last_flight.trip_section + 1
      else
        return last_flight.trip_section
      end
    else
      return 1
    end
  end

  # Within a trip section, calculates the ratio of the sum of the direct flight
  # distances of each {Flight} to the distance of a direct flight between the
  # first origin and last destination. If the trip section has no flights, or
  # if the trip section covers no net distance (it begins and ends at the same
  # airport), then this method returns nil.
  # 
  # This calculation is used to determine how "bad" a layover is in terms of
  # extra distance added. A layover ratio of 1 means any layovers did not add
  # any distance to the trip section. Higher numbers represent how many times
  # longer the trip was; for example, a layover ratio of 2 means the trip
  # section distance was twice as long as the theoretical best distance.
  #
  # @param section [Integer] the section of this trip to calculate the layover
  #   ratio for
  # @return [Float, nil] the layover ratio
  def layover_ratio(section)
    flights = self.flights.where(trip_section: section).order(:departure_utc)
    return nil unless flights.any?
    ideal_distance = Route.distance_by_airport(flights.first.origin_airport, flights.last.destination_airport)
    return nil unless (ideal_distance && ideal_distance > 0)
    flown_distance = flights.total_distance(false)
    return nil unless flown_distance
    return (flown_distance.to_f)/(ideal_distance.to_f)
  end

  # Returns an array of all trips associated with a collection of flights,
  # including ID, name, hidden status, departure date, and an array of trip
  # sections (with section numbers and departure dates) that also match the
  # flights.
  # 
  # Sections which do not match any flights will not be included, even if their
  # parent trip does match one or more flights.
  #
  # Used by {AirportsController#show} to generate tables of trips and trip
  # sections matching an airport.
  #
  # @param flights [Array<Flight>] a collection of {Flight Flights}
  # @return [Array<Hash>] trips and subsections which include one or more
  #   {Flight Flights} in the collection.
  #
  # @example
  #   Trip.matching_trips_and_sections(Flight.first(20)) #=> [
  #     {trip_id: 1, name: "Name", hidden: false, departure_date: "2010-01-01", sections: [
  #       {trip_section: 1, departure_date: "2010-01-01"}
  #       {trip_section: 2, departure_date: "2010-01-02"}
  #     ]}
  #   ]
  def self.matching_trips_and_sections(flights)
    
    # Organize sections by trip:
    trip_hash = Hash.new{ |h,k| h[k] = {sections: Hash.new} }
    trip_section_pairs = flights.pluck(:trip_id, :trip_section, :departure_date).uniq.sort_by{|x| x[2]}
    trip_section_pairs.each do |p|
      # Add the flight date, unless an earlier date is already present:
      current_date = trip_hash.dig(p[0], :sections, p[1])
      trip_hash[p[0]][:sections][p[1]] = [current_date, p[2]].compact.min
    end

    # Get trip names:
    trip_names = Hash[Trip.find(trip_hash.keys).pluck(:id, :name, :hidden).map{|t| [t[0], {name: t[1], hidden: t[2]}]}]

    # Create output array:
    return trip_hash.map{|tk,tv| {trip_id: tk, name: trip_names[tk][:name], hidden: trip_names[tk][:hidden], departure_date: tv[:sections].values.min, sections: tv[:sections].map{|sk,sv| {trip_section: sk, departure_date: sv}}}}.sort_by{|t| t[:departure_date]}

  end

  # Generates the WHERE clause of a SQL query for all flights in all sections
  # specified in a {matching_trips_and_sections} array.
  #
  # @param matching_trips_and_sections_array [Array<Hash>] the results of a
  #   {matching_trips_and_sections} call
  # @return [String] a SQL where clause
  # 
  # @see matching_trips_and_sections
  def self.section_where_array(matching_trips_and_sections_array)
    return matching_trips_and_sections_array.map{|t| t[:sections].map{|s| [t[:trip_id],s[:trip_section]]}}.flatten(1).map{|pair| "(trip_id = " + pair[0].to_i.to_s + " AND trip_section = " + pair[1].to_i.to_s + ")"}.join(" OR ")
  end
  
  # Returns a collection of trip IDs, names, and departure dates. Used in
  # {TripsController#index} to show a list of trips.
  #
  # @param flyer [User] the {User} whose trips are to be shown
  # @param current_user [User, nil] the {User} (or visitor if nil) viewing the
  #   list of trips
  # @return [Array<Hash>] an array of trip details
  def self.with_departure_dates(flyer, current_user, sort_category=nil, sort_direction=nil)
    if flyer == current_user
      trips = Trip.find_by_sql(["SELECT flights.trip_id, trips.id, trips.name, trips.hidden, MIN(flights.departure_date) AS departure_date FROM flights JOIN trips ON flights.trip_id = trips.id WHERE trips.user_id = 1 GROUP BY flights.trip_id, trips.id, trips.name, trips.hidden ORDER BY departure_date", flyer.id])
    else
      trips = Trip.find_by_sql(["SELECT flights.trip_id, trips.id, trips.name, trips.hidden, MIN(flights.departure_date) AS departure_date FROM flights JOIN trips ON flights.trip_id = trips.id WHERE trips.user_id = ? AND trips.hidden = false GROUP BY flights.trip_id, trips.id, trips.name, trips.hidden ORDER BY departure_date", flyer.id])
    end

    trips.reverse! if sort_category == :departure && sort_direction == :desc
  
    return trips
  end
  
  # Returns a collection of Trips which have no {Flight Flights}. Used in
  # {TripsController#index} to allow a verified {User} to select a Trip which
  # they have not yet added any {Flight Flights} to.
  #
  # @return [Array<Trip>] Trips with no {Flight Flights}
  def self.with_no_flights
    return Trip.where("id not in (?)",Trip.distinct.joins(:flights).select("trips.id"))
  end
    
  protected

  # Converts blank form fields to nil before saving them to the database.
  #
  # @return [Hash]
  def nil_if_blank
    NULL_ATTRS.each { |attr| self[attr] = nil if self[attr].blank? }
  end
end
