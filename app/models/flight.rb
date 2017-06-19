class Flight < ApplicationRecord
  belongs_to :trip
  belongs_to :origin_airport, :class_name => 'Airport'
  belongs_to :destination_airport, :class_name => 'Airport'
  belongs_to :airline
  belongs_to :aircraft_family
  belongs_to :operator, :class_name => 'Airline'
  belongs_to :codeshare_airline, :class_name => 'Airline'
    
  # Returns a hash containing the AircraftFamily for the flight's family, and
  # the AircraftFamily for the flight's subtype if available
  def aircraft_family_and_type
    return nil unless aircraft_family
    return {family: aircraft_family} if aircraft_family.is_family?
    return {family: aircraft_family.parent, type: aircraft_family}
  end
  
  NULL_ATTRS = %w( flight_number aircraft_name tail_number travel_class comment fleet_number boarding_pass_data )
  STRIP_ATTRS = %w( operator fleet_number aircraft_family aircraft_name tail_number )
  
  before_save :nil_if_blank
  before_save :strip_blanks
  
  validates :origin_airport_id, :presence => true
  validates :destination_airport_id, :presence => true
  validates :trip_id, :presence => true
  validates :trip_section, :presence => true
  validates :departure_date, :presence => true
  validates :departure_utc, :presence => true
  validates :airline_id, presence: true
  validates :travel_class, :inclusion => { in: TravelClass.list.keys, message: "%{value} is not a valid travel class" }, :allow_nil => true, :allow_blank => true
  
  scope :chronological, -> {
    order('flights.departure_utc')
  }
  scope :flights_table, -> {
    select("flights.id, flights.flight_number, flights.departure_date, flights.origin_airport_id, flights.destination_airport_id, flights.trip_section, flights.trip_id, flights.aircraft_family_id, flights.travel_class, flights.airline_id, airlines.airline_name, airlines.iata_airline_code, operators_flights.iata_airline_code AS operator_iata_airline_code, operators_flights.airline_name AS operator_name, aircraft_families.family_name, aircraft_families.iata_aircraft_code, aircraft_families.manufacturer, airports.iata_code AS origin_iata_code, airports.id AS origin_airport_id, airports.city AS origin_city, airports.country AS origin_country, destination_airports_flights.iata_code AS destination_iata_code, destination_airports_flights.id AS destination_airport_id, destination_airports_flights.city AS destination_city, destination_airports_flights.country AS destination_country, trips.hidden, trips.name AS trip_name").
    joins(:airline, :origin_airport, :destination_airport, :trip).joins("LEFT OUTER JOIN airlines AS operators_flights ON operators_flights.id = flights.operator_id LEFT OUTER JOIN aircraft_families ON aircraft_families.id = flights.aircraft_family_id").
    order(:departure_utc)
  }  
  scope :visitor, -> {
    joins(:trip).
    where('hidden = FALSE')
  }
  
  protected
  
  def nil_if_blank
    NULL_ATTRS.each { |attr| self[attr] = nil if self[attr].blank? }
  end
  
  def strip_blanks
    STRIP_ATTRS.each { |attr| self[attr] = self[attr].strip if !self[attr].blank? }
  end
  
  def self.aircraft_first_flight(aircraft_family)
    return Flight.select("aircraft_families.iata_aircraft_code, flights.departure_date").joins(:aircraft_family).where(aircraft_family_id: aircraft_family).order(departure_date: :asc).first.departure_date
  end
  
  def self.airline_first_flight(airline)
    return Flight.select("airlines.iata_airline_code, flights.departure_date").joins(:airline).where("airlines.iata_airline_code = ?", airline).order(departure_date: :asc).first.departure_date
  end
  
  def self.airport_first_visit(airport_id)
    return Flight.where("origin_airport_id = ? OR destination_airport_id = ?", airport_id, airport_id).order(departure_date: :asc).first.departure_date
  end
  
  # For a given flight collection, return a hash with years as the keys, and
  # hashes of counts of business, mixed, and personal flights as the values.
  # by_year[2009] = {business: 35, mixed: 4, personal: 7}
  # Years with no flights that are between the earliest and latest flight will
  # be included, with zeroes in the values.
  def self.by_year
    # Create hash ranging from earliest to latest years (default all values to zero):
    summary = Hash.new
    if self.year_range
      self.year_range.each do |year|
        summary[year] = {business: 0, mixed: 0, personal: 0, undefined: 0}
      end
    end
    
    # Loop through all flights (with year and flight.trip.purpose selected and increment hash):
    flights = self.select("departure_date, trips.purpose AS purpose").joins("LEFT OUTER JOIN trips ON trips.id = flights.trip_id")
    flights.each do |flight|
      purpose = flight.purpose ? flight.purpose.to_sym : :undefined
      summary[flight.departure_date.year][purpose] += 1
    end
    
    return summary
  end
  
  # Accepts a date range, and returns all classes that had their
  # first flight in this date range.
  def self.new_class_in_date_range(date_range, logged_in=false)
    flights = logged_in ? Flight.all : Flight.visitor
    first_flights = flights.select(:travel_class, :departure_date).where.not(travel_class: nil).group(:travel_class).minimum(:departure_date)
    return first_flights.select{|k,v| date_range.include?(v)}.map{|k,v| k}.sort
  end
  
  # For a given flight collection, return a range of the years that contain
  # flights.
  def self.year_range
    return nil unless self.any?
    sorted = self.chronological
    return sorted.first.departure_date.year..sorted.last.departure_date.year
  end
  
  # For a given flight collection, return an array of years containing flights.
  def self.years_with_flights
    flights = self.chronological
    years_with_flights = Array.new
    flights.each do |flight|
      years_with_flights.push(flight.departure_date.year)
    end
    return years_with_flights.uniq
  end
  
  
  
end
