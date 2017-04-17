class AircraftFamily < ApplicationRecord
  belongs_to :parent, class_name: "AircraftFamily", foreign_key: "parent_id"
  has_many :children, class_name: "AircraftFamily", foreign_key: "parent_id"
  has_many :flights
  
  
  def self.categories_list
    categories = Hash.new
    categories['wide_body'] = 'Wide-body'
    categories['narrow_body'] = 'Narrow-body'
    categories['regional_jet'] = 'Regional Jet'
    categories['turboprop'] = 'Turboprop'
    return categories
  end
  
  validates :family_name, presence: true
  validates :iata_aircraft_code, presence: true, length: { is: 3 }, uniqueness: true
  validates :manufacturer, presence: true
  validates :category, inclusion: { in: categories_list.keys, message: "%{value} is not a valid category" }, allow_nil: false, allow_blank: false
  
  def format_name
    return self.family_name
  end
  
  def full_name
    return self.manufacturer + " " + self.family_name
  end
  
  # Returns an array of aircraft families, with a hash for each family
  # containing the aircraft manufacturer, name, IATA code, and number
  # of flights on that aircraft, sorted by number of flights descending.
  def self.flight_count(logged_in=false)
    flights = logged_in ? Flight.all : Flight.visitor
    flights.joins(:aircraft_family).group(:aircraft_family_id, :manufacturer, :family_name, :iata_aircraft_code).count
      .map{|k,v| {id: k[0], manufacturer: k[1], family_name: k[2], iata_aircraft_code: k[3], flight_count: v}}
      .sort_by{|a| [-a[:flight_count], a[:manufacturer], a[:family_name]]}
  end

end
