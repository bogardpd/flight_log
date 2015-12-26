class Airline < ActiveRecord::Base
  has_many :flights
  has_many :operated_flights, :class_name => 'Flight', :foreign_key => 'operator_id'
    
  validates :iata_airline_code, :presence => true, :length => { :minimum => 2 }, :uniqueness => { :case_sensitive => false }
  validates :airline_name, :presence => true
  
  def all_flights(logged_in)
    # Returns a collection of Flights that have this airport as an origin or destination.
    if logged_in
      flights = Flight.chronological.where("airline_id = :airline_id", {:airline_id => self})
    else
      flights = Flight.visitor.chronological.where("airline_id = :airline_id", {:airline_id => self})
    end
    return flights
  end
  
  def format_name
    return "#{self.airline_name}".html_safe
  end
  
end
