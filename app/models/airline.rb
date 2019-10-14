# Defines a model for airlines.
#
# Airlines can be used in multiple ways in this application:
# 
# * *Administrating* *airline*: The entity responsible for administrating a
#   {Flight}. This is generally the airline who provides the livery for the
#   plane, the branding at the gate, the airline name on the airport flight
#   status screens, flight planning, and so on.
# * *Operator*: The entity which actually operates a {Flight}. Sometimes this
#   will be the same as the administrating airline, and sometimes the
#   administrating airline will contract this flight to another airline which
#   operates the flight under the administrating airline's branding.
# * *Codeshare*: An Airline which sold a ticket on second airline's {Flight}.
#   Often used when the airline the ticket is purchased from doesn't serve one
#   or more of the airports on the itinerary. The second airline may
#   potentially also be the operator of the flight, or they may further
#   contract it to a third operator airline which flies under the second
#   airline’s branding.
#
# Thus, the {Flight} model has Airline ID columns for each of the above types.
# The (administrating) airline ID is required, and the operator and codeshare
# airline IDs are optional.
class Airline < ApplicationRecord
  has_many :flights
  has_many :operated_flights, class_name: "Flight", foreign_key: "operator_id"
  has_many :codeshared_flights, class_name: "Flight", foreign_key: "codeshare_airline_id"
    
  validates :iata_airline_code, presence: true, length: { is: 2 }
  validates :icao_airline_code, presence: true, length: { is: 3 }
  validates :slug, presence: true, uniqueness: { case_sensitive: false }
  validates :airline_name, presence: true
  validates :numeric_code, length: { is: 3, allow_blank: true }
  
  # Form fields which should be saved capitalized.
  CAPS_ATTRS = %w( icao_airline_code )
  before_save :capitalize_codes
  
  # Formats the name of this Airline.
  #
  # This method currently applies no additional formatting; it's used as a
  # placeholder in case formatting is needed in the future.
  # 
  # @return [String] the Airline name
  def format_name
    return self.airline_name
  end

  # Returns true if the Airline is the marketing, operating, or codeshare
  # airline for any {Flight}. Used to check whether or not the airline can be
  # deleted without affecting any flights.
  #
  # @return [Boolean] whether or not this airline is used by any {Flight} in any
  #   way
  def has_any_airline_operator_codeshare_flights?
    return Flight.where(airline_id: self.id).or(Flight.where(operator_id: self.id)).or(Flight.where(codeshare_airline_id: self.id)).any?
  end
  
  # Returns an array of Airlines, with a hash for each Airline containing the
  # id, airline name, slug, IATA code, and number of {Flight Flights} flown by
  # that Airline, sorted by number of flights descending.
  # 
  # Used on various "index" and "show" views to generate a table of airlines
  # and their flight counts.
  #
  # @param flights [Array<Flight>] a collection of {Flight Flights} to
  #   calculate Airline flight counts for
  # @param sort_category [:airline, :code, :flights] the category to sort
  #   the array by
  # @param sort_direction [:asc, :desc] the direction to sort the array
  # @param type [:airline, :operator] whether to calculate {Flight} counts for
  #   Airlines administrating flights (:airline) or Airlines operating flights
  #   (:operator)
  # @return [Array<Hash>] details for each Airline flown
  def self.flight_table_data(flights, sort_category=nil, sort_direction=nil, type: :airline)
    
    id_field = (type == :airline) ? :airline_id : :operator_id
    counts = flights.reorder(nil).joins(type).group(id_field, "airlines.airline_name", "airlines.slug", "airlines.iata_airline_code", "airlines.icao_airline_code").count
      .map{|k,v| {id: k[0], airline_name: k[1], slug: k[2], iata_airline_code: k[3], icao_airline_code: k[4], flight_count: v}}
    
    case sort_category
    when :airline
      counts.sort_by!{|airline| airline[:airline_name]&.downcase || ""}
      counts.reverse! if sort_direction == :desc
    when :code
      counts.sort_by!{|airline| airline[:iata_airline_code]&.downcase || ""}
      counts.reverse! if sort_direction == :desc
    when :flights
      sort_mult = (sort_direction == :desc ? -1 : 1)
      counts.sort_by!{|airline| [sort_mult * airline[:flight_count], airline[:airline_name]&.downcase || ""]}
    else
      counts.sort_by!{|airline| [-airline[:flight_count], airline[:airline_name]&.downcase || ""]}
    end
    
    # Count flights without airlines:
    airline_sum = counts.reduce(0){|sum, f| sum + f[:flight_count]}
    if flights.size > airline_sum
       counts.push({id: nil, flight_count: flights.size - airline_sum})
    end
    return counts
  end
  
  # Accepts an airline IATA code, and returns the matching ICAO code.
  #
  # @param iata [String] the airline IATA code to look up
  # @param keep_iata [Boolean] whether or not to return the provided IATA code
  #   if an ICAO code is not found. If this is false, the method will return
  #   nil if an ICAO code is not found.
  # @return [String, nil] a matching ICAO code if found, the provided IATA code or nil if not found
  def self.convert_iata_to_icao(iata, keep_iata=true)
    airline = Airline.find_by(iata_airline_code: iata)
    if airline.nil?
       return keep_iata ? iata : nil
    end
    icao = airline.icao_airline_code
    return icao if icao
    return keep_iata ? iata : nil
  end
  
  # Accepts a flyer, the current user, and a date range, and returns all
  # airlines that had their first administrated flight in this date range. Used
  # on {FlightsController#show_date_range} to highlight new airlines.
  #
  # @param flyer [User] the {User} whose flights should be searched
  # @param current_user [User, nil] the {User} viewing the flights
  # @param date_range [Range<Date>] the date range to search
  # @return [Array<Integer>] an array of Airline IDs
  def self.new_in_date_range(flyer, current_user, date_range)
    flights = flyer.flights(current_user).reorder(nil)
    first_flights = flights.joins(:airline).select(:airline_id, :departure_date).where.not(airline_id: nil).group(:airline_id).minimum(:departure_date)
    return first_flights.select{|k,v| date_range.include?(v)}.map{|k,v| k}.sort
  end
  
  protected
  
  # Capitalizes form fields before saving them to the database.
  #
  # @return [Hash]
  def capitalize_codes
    CAPS_ATTRS.each { |attr| self[attr] = self[attr].upcase if !self[attr].blank? }
  end
  
end
