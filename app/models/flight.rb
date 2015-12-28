class Flight < ActiveRecord::Base
  belongs_to :trip
  belongs_to :origin_airport, :class_name => 'Airport'
  belongs_to :destination_airport, :class_name => 'Airport'
  belongs_to :airline
  belongs_to :operator, :class_name => 'Airline'
  belongs_to :codeshare_airline, :class_name => 'Airline'
    
  NULL_ATTRS = %w( flight_number aircraft_family aircraft_variant aircraft_name tail_number travel_class comment fleet_number )
  STRIP_ATTRS = %w( operator fleet_number aircraft_family aircraft_variant aircraft_name tail_number )
  
  before_save :nil_if_blank
  before_save :strip_blanks
  
  validates :origin_airport_id, :presence => true
  validates :destination_airport_id, :presence => true
  validates :trip_id, :presence => true
  validates :trip_section, :presence => true
  validates :departure_date, :presence => true
  validates :departure_utc, :presence => true
  validates :airline_id, presence: true
  validates :travel_class, :inclusion => { :in => %w(Economy Business First), :message => "%{value} is not a valid travel class" }, :allow_nil => true, :allow_blank => true
  
  scope :chronological, -> {
    order('flights.departure_utc')
  }
  scope :visitor, -> {
    joins(:trip).
    where('hidden = FALSE')
  }
  
  scope :flights_table, -> {
    select("flights.id, flights.flight_number, flights.departure_date, flights.origin_airport_id, flights.destination_airport_id, flights.trip_section, flights.trip_id, flights.aircraft_family, airlines.airline_name, airlines.iata_airline_code, airports.iata_code AS origin_iata_code, airports.id AS origin_airport_id, airports.city AS origin_city, destination_airports_flights.iata_code AS destination_iata_code, destination_airports_flights.id AS destination_airport_id, destination_airports_flights.city AS destination_city, trips.hidden").
    joins(:airline, :origin_airport, :destination_airport, :trip).
    order(:departure_utc)
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
    return Flight.where(:aircraft_family => aircraft_family).order(departure_date: :asc).first.departure_date
  end
  
  def self.airline_first_flight(airline)
    return Flight.where(:airline => airline).order(departure_date: :asc).first.departure_date
  end
  
  def self.airport_first_visit(airport_id)
    return Flight.where("origin_airport_id = ? OR destination_airport_id = ?", airport_id, airport_id).order(departure_date: :asc).first.departure_date
  end
  
end
