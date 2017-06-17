class Airline < ApplicationRecord
  has_many :flights
  has_many :operated_flights, :class_name => 'Flight', :foreign_key => 'operator_id'
  has_many :codeshared_flights, :class_name => 'Flight', :foreign_key => 'codeshare_airline_id'
    
  validates :iata_airline_code, :presence => true, :length => { :minimum => 2 }, :uniqueness => { :case_sensitive => false }
  validates :icao_airline_code, :presence => true, :length => { is: 3 }, :uniqueness => { :case_sensitive => false }
  validates :airline_name, :presence => true
  validates :numeric_code, :length => { :is => 3, :allow_blank => true }
  
  CAPS_ATTRS = %w( icao_airline_code )
  before_save :capitalize_codes
  
  def format_name
    return self.airline_name
  end
  
  # Returns an array of airlines, with a hash for each family containing the
  # id, airline name, IATA code, and number of flights on that airline, sorted
  # by number of flights descending.
  def self.flight_count(logged_in=false, type: :airline, flights: nil)
    flights ||= Flight.all
    flights = flights.visitor unless logged_in
    id_field = (type == :airline) ? :airline_id : :operator_id
    counts = flights.joins(type).group(id_field, :airline_name, :iata_airline_code).count
      .map{|k,v| {id: k[0], airline_name: k[1], iata_airline_code: k[2], flight_count: v}}
      .sort_by{|a| [-a[:flight_count], a[:airline_name]]}
    
    airline_sum = counts.reduce(0){|sum, f| sum + f[:flight_count]}
    if flights.count > airline_sum
      counts.push({id: nil, flight_count: flights.count - airline_sum})
    end
    return counts
  end
  
  # Accepts an ICAO code, and attempts to look up the ICAO code. If it does not
  # find an ICAO code, it returns the provided IATA code.
  def self.convert_iata_to_icao(iata)
    airline = Airline.find_by(iata_airline_code: iata)
    return iata if airline.nil?
    icao = airline.icao_airline_code
    return icao.nil? ? iata : icao
  end
  
  # Accepts a date range, and returns all airlines that had their
  # first flight in this date range.
  def self.new_in_date_range(date_range, logged_in=false)
    flights = logged_in ? Flight.all : Flight.visitor
    first_flights = flights.joins(:airline).select(:airline_id, :departure_date).where.not(airline_id: nil).group(:airline_id).minimum(:departure_date)
    return first_flights.select{|k,v| date_range.include?(v)}.map{|k,v| k}.sort
  end
  
  protected
  
  def capitalize_codes
    CAPS_ATTRS.each { |attr| self[attr] = self[attr].upcase if !self[attr].blank? }
  end
  
end
