class Airline < ApplicationRecord
  has_many :flights
  has_many :operated_flights, :class_name => 'Flight', :foreign_key => 'operator_id'
  has_many :codeshared_flights, :class_name => 'Flight', :foreign_key => 'codeshare_airline_id'
    
  validates :iata_airline_code, :presence => true, :length => { :minimum => 2 }, :uniqueness => { :case_sensitive => false }
  validates :airline_name, :presence => true
  validates :numeric_code, :length => { :is => 3, :allow_blank => true }
  
  
  def format_name
    return self.airline_name
  end
  
  # Returns an array of airlines, with a hash for each family containing the
  # id, airline name, IATA code, and number of flights on that airline, sorted
  # by number of flights descending.
  def self.flight_count(logged_in=false, type=:airline)
    flights = logged_in ? Flight.all : Flight.visitor
    id_field = (type == :airline) ? :airline_id : :operator_id
    flights.joins(type).group(id_field, :airline_name, :iata_airline_code).count
      .map{|k,v| {id: k[0], airline_name: k[1], iata_airline_code: k[2], flight_count: v}}
      .sort_by{|a| [-a[:flight_count], a[:airline_name]]}
  end
  
end
