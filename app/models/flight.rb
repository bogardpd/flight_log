class Flight < ActiveRecord::Base
  belongs_to :trip
  belongs_to :origin_airport, :class_name => 'Airport'
  belongs_to :destination_airport, :class_name => 'Airport'
  belongs_to :airline
  belongs_to :aircraft_family
  belongs_to :operator, :class_name => 'Airline'
  belongs_to :codeshare_airline, :class_name => 'Airline'
  
  def self.classes_list
    classes = Hash.new
    classes['F'] = 'First'
    classes['J'] = 'Business'
    classes['W'] = 'Premium Economy'
    classes['Y'] = 'Economy'
    return classes
  end
    
  NULL_ATTRS = %w( flight_number aircraft_variant aircraft_name tail_number travel_class comment fleet_number boarding_pass_data )
  STRIP_ATTRS = %w( operator fleet_number aircraft_family aircraft_variant aircraft_name tail_number, boarding_pass_data )
  
  before_save :nil_if_blank
  before_save :strip_blanks
  
  validates :origin_airport_id, :presence => true
  validates :destination_airport_id, :presence => true
  validates :trip_id, :presence => true
  validates :trip_section, :presence => true
  validates :departure_date, :presence => true
  validates :departure_utc, :presence => true
  validates :airline_id, presence: true
  validates :travel_class, :inclusion => { in: classes_list.keys, message: "%{value} is not a valid travel class" }, :allow_nil => true, :allow_blank => true
  
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
  
  
  
  def self.tail_country(tail_number)
    case tail_number.upcase
    when /^N[1-9]((\d{0,4})|(\d{0,3}[A-HJ-NP-Z])|(\d{0,2}[A-HJ-NP-Z]{2}))$/
      return "United States"
    when /^VH-[A-Z]{3}$/
      return "Australia"
    when /^C-[FGI][A-Z]{3}$/
      return "Canada"
    when /^B-((1[5-9]\d{2})|([2-9]\d{3}))$/
      return "China"
    when /^F-[A-Z]{4}$/
      return "France"
    when /^D-(([A-CE-IK-O][A-Z]{3})|(\d{4}))$/
      return "Germany"
    when /^9G-[A-Z]{3}$/
      return "Ghana"
    when /^SX-[A-Z]{3}$/
      return "Greece"
    when /^B-[HKL][A-Z]{2}$/
      return "Hong Kong"
    when /^TF-(([A-Z]{3})|([1-9]\d{2}))$/
      return "Iceland"
    when /^VT-[A-Z]{3}$/
      return "India"
    when /^4X-[A-Z]{3}$/
      return "Israel"
    when /^JA((\d{4})|(\d{3}[A-Z])|(\d{2}[A-Z]{2})|(A\d{3}))$/
      return "Japan"
    when /^JY-[A-Z]{3}$/
      return "Jordan"
    when /^9M-[A-Z]{3}$/
      return "Malaysia"
    when /^PH-(([A-Z]{3})|(1[A-Z]{2})|(\d[A-Z]\d)|([1-9]\d{2,3}))$/
      return "Netherlands"
    when /^ZK-[A-Z]{3}$/
      return "New Zealand"
    when /^9V-[A-Z]{3}$/
      return "Singapore"
    when /^B-((\d(0\d{3}|1[0-4]\d{2}))|([1-9]\d{4}))$/
      return "Taiwan"
    when /^HS-[A-Z]{3}$/
      return "Thailand"
    when /^UR-(([A-Z]{3,4})|([1-9]\d{4}))$/
      return "Ukraine"
    when /^A6-[A-Z]{3}$/
      return "United Arab Emirates"
    when /^G-(([A-Z]{4})|(\d{1,2}-\d{1,2}))$/
      return "United Kingdom"
    else
      return nil
    end
      
  end
  
  
  protected
  
  def nil_if_blank
    NULL_ATTRS.each { |attr| self[attr] = nil if self[attr].blank? }
  end
  
  def strip_blanks
    STRIP_ATTRS.each { |attr| self[attr] = self[attr].strip if !self[attr].blank? }
  end
  
  def self.aircraft_first_flight(aircraft_family)
    return Flight.select("aircraft_families.iata_aircraft_code, flights.departure_date").joins(:aircraft_family).where("aircraft_families.iata_aircraft_code = ?", aircraft_family).order(departure_date: :asc).first.departure_date
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
    summary = Hash.new
    
    # Get earliest and latest flight years (use whatever generates year selector on show flights):
    
    
    # Create hash ranging from earliest to latest years (default all values to zero):
    
    
    # Loop through all flights (with year and flight.trip.purpose selected and increment hash):
    
    
    
    
    
    summary[2009] = {business: 35, mixed: 4, personal: 7}
    summary[2010] = {business: 41, mixed: 4, personal: 4}
    return summary
  end
  
  # Return a range of the years that contain flights for a given flight
  # collection
  def self.year_range
    return nil unless self.any?
    sorted = self.chronological
    return sorted.first.departure_date.year..sorted.last.departure_date.year
  end
  
  # For a given flight collection, return a hash with years as the keys and
  # values of true (if the year has flights) or false.
  def self.years_with_flights
    flights = self.chronological
    
    years_with_flights = Hash.new(false)
    flights.each do |flight|
      years_with_flights[flight.departure_date.year] = true
    end
    return years_with_flights
  end
  
end
