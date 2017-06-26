class AircraftFamily < ApplicationRecord
  belongs_to :parent, class_name: "AircraftFamily", foreign_key: "parent_id"
  has_many :children, class_name: "AircraftFamily", foreign_key: "parent_id"
  has_many :flights
  
  scope :families, -> { where(parent_id: nil) }
  scope :types,    -> { where.not(parent_id: nil) }
  scope :with_no_flights, -> { where('id not in (?)', self.distinct.joins(:flights).select("aircraft_families.id")) }
    
  def self.categories_list
    categories = Hash.new
    categories['wide_body'] = 'Wide-body'
    categories['narrow_body'] = 'Narrow-body'
    categories['regional_jet'] = 'Regional Jet'
    categories['turboprop'] = 'Turboprop'
    return categories
  end
  
  validates :family_name, presence: true
  validates :iata_aircraft_code, length: { is: 3 }, allow_blank: true
  validates :icao_aircraft_code, length: { in: 2..4 }, uniqueness: { case_sensitive: false }, allow_blank: true
  validates :manufacturer, presence: true
  validates :category, inclusion: { in: categories_list.keys, message: "%{value} is not a valid category" }, allow_nil: false, allow_blank: false
  
  CAPS_ATTRS = %w( iata_aircraft_code icao_aircraft_code )
  before_save :capitalize_codes
  
  # Returns the aircraft's IATA aircraft code if it is an aircraft family, or
  # the ICAO code if it is an aircraft type.
  def code
    return self.is_family? ? self.iata_aircraft_code : self.icao_aircraft_code
  end
  
  # Returns an array containing the current family's ID and the IDs of all
  # child types.
  def family_and_subtype_ids
    ids = Array.new
    ids.push(id)
    ids.push(children.pluck(:id))
    return ids.flatten
  end
  
  # Returns an array containing ids, family names, icao codes, and flight counts.
  def family_and_subtype_count(logged_in=false)
    flights = logged_in ? Flight.all : Flight.visitor
    type_count = flights.where(aircraft_family_id: family_and_subtype_ids).joins(:aircraft_family)
      .group(:aircraft_family_id, :family_name, :icao_aircraft_code, :parent_id).count
      .map{|k,v| {id: k[0], family_name: k[1], icao_aircraft_code: k[2], is_family: k[3].nil?, flight_count: v}}
      .sort_by{|a| [-a[:flight_count], a[:family_name]] }
  end
  
  def format_name
    return self.family_name
  end
  
  def full_name
    return self.manufacturer + " " + self.family_name
  end
  
  # Return true if this aircraft type is a top-level family, false otherwise.
  def is_family?
    return parent_id.nil?
  end
  
  # Returns the location of illustration of a particular aircraft type, or nil
  # if the illustration doesn't exist
  def illustration_location
    dir = self.is_family? ? "iata" : "icao"
    image_location = "aircraft_illustrations/#{dir}/#{self.code}.jpg"
    if Rails.application.assets.find_asset(image_location)
      return image_location
    else
      return nil
    end
  end
  
  # Returns the type ID for a given ICAO or IATA code
  def self.find_id_from_code(airline_code)
    from_icao = self.find_by(icao_aircraft_code: airline_code)
    return from_icao.id if from_icao
    from_iata = self.find_by(iata_aircraft_code: airline_code)
    return from_iata.id if from_iata
    return nil
  end
  
  # Returns an array of aircraft families (only those without parents), with a
  # hash for each family containing the aircraft manufacturer, name, IATA code,
  # and number of flights on that aircraft, sorted by number of flights
  # descending. Child types are included with the parent family count. If a
  # collection of flights is provided, the count will be conducted on that
  # collection; otherwise, it will be conducted on all flights.
  def self.flight_count(logged_in=false, flights: nil)
    flights ||= Flight.all
    flights = flights.visitor unless logged_in
    family_count = flights.joins(:aircraft_family).group(:aircraft_family_id, :parent_id).count
      .map{|k,v| {(k[1]||k[0]) => v}} # Create array of hashes with k as parent id or family id and v as count
      .reduce{|a,b| a.merge(b){|k,old_v,new_v| old_v + new_v}} # Group and sum family counts
    family_count ||= Array.new
      
    counts = self.families.map{|f| {id: f.id, manufacturer: f.manufacturer, family_name: f.family_name, iata_aircraft_code: f.iata_aircraft_code, flight_count: family_count[f.id] || 0}}
      .sort_by{|a| [-a[:flight_count], a[:manufacturer].downcase, a[:family_name].downcase]}
    
    family_sum = counts.reduce(0){|sum, f| sum + f[:flight_count]}
    if flights.count > family_sum
      counts.push({id: nil, flight_count: flights.count - family_sum})
    end  
    return counts
  end

  def self.family_select_options
    self.families.pluck(:manufacturer, :family_name, :id).sort_by{|af| [af[0].downcase,af[1].downcase]}.map{|af| [[af[0],af[1]].join(" "), af[2]]}
  end
  
  # Returns a nested array of families and types in a format ready for
  # grouped_options_for_select
  def self.grouped_types
    types = self.types.map{|f| {family_id: f.parent_id, family_name: f.family_name, id: f.id}}
    families = self.families.order(:manufacturer, :family_name)
    return families.map{|f| {f.id => {family_name: f.family_name, manufacturer: f.manufacturer}}}
      .reduce{|a,b| a.merge(b)}
      .map{|k,v| ["#{v[:manufacturer]} #{v[:family_name]} Family"].push(([{family_name: "Unknown type of #{v[:family_name]}", id: k}]+types.select{|t| t[:family_id] == k}).map{|t| [t[:family_name], t[:id]]})}
  end
  
  # Accepts a date range, and returns all aircraft families that had their
  # first flight in this date range.
  def self.new_in_date_range(date_range, logged_in=false)
    flights = logged_in ? Flight.all : Flight.visitor
    first_flights = flights.joins(:aircraft_family).select(:aircraft_family_id, :parent_id, :departure_date).where.not(aircraft_family_id: nil).group(:aircraft_family_id, :parent_id).minimum(:departure_date)
    family_first_flights = first_flights.map{|k,v| {(k[1]||k[0]) => v}}
      .reduce{|a,b| a.merge(b){|k,oldval,newval| [oldval,newval].min}}
    return family_first_flights.select{|k,v| date_range.include?(v)}.map{|k,v| k}.sort
  end
  
  protected
  
  def capitalize_codes
    CAPS_ATTRS.each { |attr| self[attr] = self[attr].upcase if !self[attr].blank? }
  end

end
