class AircraftFamily < ApplicationRecord
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

end
