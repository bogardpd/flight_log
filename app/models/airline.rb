class Airline < ActiveRecord::Base
  has_many :flights
  has_many :operated_flights, :class_name => 'Flight', :foreign_key => 'operator_id'
  has_many :codeshared_flights, :class_name => 'Flight', :foreign_key => 'codeshare_airline_id'
    
  validates :iata_airline_code, :presence => true, :length => { :minimum => 2 }, :uniqueness => { :case_sensitive => false }
  validates :airline_name, :presence => true
  validates :numeric_code, :length => { :is => 3 }
  
  
  def format_name
    return self.airline_name
  end
  
end
