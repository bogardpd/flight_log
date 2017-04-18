class AircraftFamily < ApplicationRecord
  belongs_to :parent, class_name: "AircraftFamily", foreign_key: "parent_id"
  has_many :children, class_name: "AircraftFamily", foreign_key: "parent_id"
  has_many :flights
  
  scope :families, -> { where(parent_id: nil) }
  
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
  
  # Returns an array containing the current family's ID and the IDs of all
  # child types.
  def family_and_subtype_ids
    ids = Array.new
    ids.push(id)
    ids.push(children.pluck(:id))
    return ids.flatten
  end
  
  def format_name
    return self.family_name
  end
  
  def full_name
    return self.manufacturer + " " + self.family_name
  end
  
  # Returns an array of aircraft families (only those without parents), with a
  # hash for each family containing the aircraft manufacturer, name, IATA code,
  # and number of flights on that aircraft, sorted by number of flights
  # descending. Child types are included with the parent family count.
  def self.flight_count(logged_in=false)
    flights = logged_in ? Flight.all : Flight.visitor
    family_count = flights.joins(:aircraft_family).group(:aircraft_family_id, :parent_id).count
      .map{|k,v| {(k[1]||k[0]) => v}} # Create array of hashes with k as parent id or family id and v as count
      .reduce{|a,b| a.merge(b){|k,old_v,new_v| old_v + new_v}} # Group and sum family counts
      
    self.families.map{|f| {manufacturer: f.manufacturer, family_name: f.family_name, iata_aircraft_code: f.iata_aircraft_code, flight_count: family_count[f.id] || 0}}.sort_by{|a| [-a[:flight_count], a[:manufacturer], a[:family_name]]}
  end

end
