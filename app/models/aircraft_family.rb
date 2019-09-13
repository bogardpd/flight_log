# Defines a model for aircraft families.
#
# For the purposes of this application, an AircraftFamily object can either be
# a parent *family* (e.g. Boeing 737), or a child *type* (e.g. Boeing 737-800).
# A family can have zero to many types, but each type must have exactly one
# family. The relationship is defined by a parent_id column, which is nil for
# parent families, but set for child types.
#
# Generally, a {Flight} would refer to an AircraftFamily type for its
# aircraft_family_id; however, if the specific type is not known, it can
# refer to an AircraftFamily family.
#
# Aircraft types are defined by ICAO codes; if two aircraft variants have the
# same ICAO type designator, then they are considered the same aircraft type
# within this application. Aircraft families are defined by the most generic
# IATA type code available – preferably an IATA code covering an entire family
# of aircraft, but if not, the IATA code for the most common variant of that
# family should be used.
class AircraftFamily < ApplicationRecord
  belongs_to :parent, class_name: "AircraftFamily", foreign_key: "parent_id"
  has_many :children, class_name: "AircraftFamily", foreign_key: "parent_id"
  has_many :flights
  
  scope :families, -> { where(parent_id: nil) }
  scope :types,    -> { where.not(parent_id: nil) }
  scope :with_no_flights, -> { where("id not in (?)", self.distinct.joins(:flights).select("aircraft_families.id")) }
  
  # Defines the possible categories for an aircraft family. Currently, this is
  # only used for validation.
  # 
  # This is intended to be used in a future capability to show maps of flights
  # by aircraft family category.
  #
  # @return [Hash<String, String>] the column value and text description of
  #   each category
  def self.categories_list
    categories = Hash.new
    categories["wide_body"] = "Wide-body"
    categories["narrow_body"] = "Narrow-body"
    categories["regional_jet"] = "Regional Jet"
    categories["turboprop"] = "Turboprop"
    return categories
  end
  
  validates :family_name, presence: true
  validates :iata_aircraft_code, length: { is: 3 }, allow_blank: true
  validates :icao_aircraft_code, length: { in: 2..4 }, uniqueness: { case_sensitive: false }, allow_blank: true
  validates :slug, presence: true, uniqueness: { case_sensitive: false }
  validates :manufacturer, presence: true
  validates :category, inclusion: { in: categories_list.keys, message: "%{value} is not a valid category" }, allow_nil: false, allow_blank: false
  
  # Form fields which should be saved capitalized.
  CAPS_ATTRS = %w( iata_aircraft_code icao_aircraft_code )
  before_save :capitalize_codes
  
  # Returns the aircraft's IATA aircraft code if it is an aircraft family, or
  # the ICAO code if it is an aircraft type.
  #
  # @return [String] the IATA or ICAO aircraft code
  def code
    return self.is_family? ? self.iata_aircraft_code : self.icao_aircraft_code
  end
  
  # Returns an array containing the current family's ID and the IDs of all
  # child types. Used to generate the queries to show all flights of a given
  # family, including its child types.
  #
  # @return [Array<Integer>] all AircraftFamily IDs affiliated with this family
  def family_and_type_ids
    ids = Array.new
    ids.push(id)
    ids.push(children.pluck(:id))
    return ids.flatten
  end
  
  # Takes a set of {Flight Flights} and breaks it down by the types of this
  # AircraftFamily, returning an array containing a hash of ID, type name, ICAO
  # code, and the number of flights for each type. Also includes a hash for
  # this family, which counts the number of flights in this family that are not
  # assigned to a specific type.
  #
  # Used to generate a table of AircraftFamily sub-types and their flight
  # frequencies when showing an AircraftFamily family.
  #
  # @param flights [Array<Flight>] the collection of {Flight Flights} to
  #   calculate sub-type flight frequencies for
  # @return [Array<Hash>] details for each sub-type flown
  # @see AircraftFamiliesController#show
  def family_and_type_count(flights)
    type_count = flights.reorder(nil).joins(:aircraft_family)
      .group(:aircraft_family_id, :slug, :family_name, :icao_aircraft_code, :parent_id).count
      .map{|k,v| {id: k[0], slug: k[1], family_name: k[2], icao_aircraft_code: k[3], is_family: k[4].nil?, flight_count: v}}
      .sort_by{|a| [-a[:flight_count], a[:family_name]] }
    return type_count
  end
  
  # Formats the name of this family/type.
  #
  # This method currently applies no additional formatting; it's used as a
  # placeholder in case formatting is needed in the future.
  # 
  # @return [String] the family/type name
  def format_name
    return self.family_name
  end
  
  # Returns the manufacturer and the family/type name.
  # 
  # @return [String] the manufacturer and the family/type name
  def full_name
    return "#{self.manufacturer} #{self.family_name}"
  end
  
  # Returns true if this AircraftFamily parent family, false if it's a child
  # type.
  # 
  # @return [Boolean] whether or not this is a parent family
  def is_family?
    return parent_id.nil?
  end
  
  # Returns the location of an illustration of this aircraft family/type, or
  # nil if the illustration doesn't exist.
  #
  # @return [String] URL for the aircraft family/type illustration
  #
  # @see http://www.norebbo.com/ Norebbo Stock Illustration and Design
  def illustration_location
    dir = self.is_family? ? "iata" : "icao"
    image_location = "#{ExternalImage::ROOT_PATH}/flights/aircraft-illustrations/#{dir}/#{self.code}.jpg"
    if ExternalImage.exists?(image_location)
      return image_location
    else
      return nil
    end
  end
  
  # Accepts a querystring parameter, and returns an array of AircraftFamilies
  # where the parameter matches the ID or slug.
  #
  # @param param [String] a querystring parameter
  # @param flyer [User] the user who flew the {Flight Flights} being viewed
  # @param current_user [User] the user viewing the {Flight Flights}
  # @return [Array<Airline>] an array of matching Airlines. Returns an empty
  #   array if no matching airlines are found.
  def self.find_by_param(param, flyer, current_user)
    return [] unless param

    aircraft = self.where(slug: param)
    if param !~ /\D/
      # Check IDs only if param is purely numeric. Avoids treating something
      # like "1-Air" as an ID of 1, since "1-Air".to_i == 73.
      aircraft = aircraft.or(self.where(id: param))
    end

    unless current_user == flyer
      # If the user is not the logged-in flyer of the flights, don't show
      # aircraft without flights
      aircraft_with_flights = flyer.flights(current_user).pluck(:aircraft_family_id).uniq
      parents_with_flights = self.where(id: aircraft_with_flights).pluck(:parent_id).uniq
      aircraft = aircraft.where(id: aircraft_with_flights | parents_with_flights)
    end

    aircraft = aircraft.order(:manufacturer, :family_name)

    return aircraft
  end

  # Returns the AircraftFamily ID for a given ICAO or IATA code.
  # 
  # @param airline_code [String] an ICAO or IATA airline type code
  # @return [Integer] an AircraftFamily ID
  def self.find_id_from_code(airline_code)
    from_icao = self.find_by(icao_aircraft_code: airline_code)
    return from_icao.id if from_icao
    from_iata = self.find_by(iata_aircraft_code: airline_code)
    return from_iata.id if from_iata
    return nil
  end
  
  # Returns an array of AircraftFamily parent families (not child types), with
  # a hash for each family containing the aircraft manufacturer, name, IATA
  # code, and number of {Flight Flights} on that aircraft family (including
  # flights on its child aircraft types), sorted by number of flights
  # descending.
  #
  # Used on various "index" and "show" views to generate a table of aircraft
  # families and their flight counts.
  #
  # @param flights [Array<Flight>] a collection of {Flight Flights} to
  #   calculate AircraftFamily flight counts for
  # @param sort_category [:aircraft, :flights] the category to sort the array
  #   by
  # @param sort_direction [:asc, :desc] the direction to sort the array
  # @return [Array<Hash>] details for each AircraftFamily flown
  def self.flight_table_data(flights, sort_category=nil, sort_direction=nil)
    family_count = flights.reorder(nil).joins(:aircraft_family).group(:aircraft_family_id, :parent_id).count
      .map{|k,v| {(k[1]||k[0]) => v}} # Create array of hashes with k as parent id or family id and v as count
      .reduce{|a,b| a.merge(b){|k,old_v,new_v| old_v + new_v}} # Group and sum family counts
    family_count ||= Array.new
      
    counts = self.families.map{|f| {id: f.id, slug: f.slug, manufacturer: f.manufacturer, family_name: f.family_name, iata_aircraft_code: f.iata_aircraft_code, flight_count: family_count[f.id] || 0}}
    
    case sort_category
    when :aircraft
      counts.sort_by!{ |aircraft_family| [aircraft_family[:manufacturer]&.downcase || "", aircraft_family[:family_name]&.downcase || ""] }
      counts.reverse! if sort_direction == :desc
    when :flights
      sort_mult = (sort_direction == :desc ? -1 : 1)
      counts.sort_by!{ |aircraft_family| [sort_mult*aircraft_family[:flight_count], aircraft_family[:family_name]&.downcase || ""] }
    else
      counts.sort_by!{|aircraft_family| [-aircraft_family[:flight_count], aircraft_family[:manufacturer].downcase, aircraft_family[:family_name].downcase]}
    end
    
    # Count flights without aircraft families:
    family_sum = counts.reduce(0){|sum, f| sum + f[:flight_count]}
    if flights.count > family_sum
      counts.push({id: nil, flight_count: flights.count - family_sum})
    end  
    return counts
  end

  # Returns an array of parent families in a format ready for
  # +options_for_select+. Used for generating aircraft parent family select boxes
  # when the {FlightsController#new new} flight form prepopulation encounters an
  # unknown aircraft ICAO code, and has to ask the user what family this new
  # type belongs to.
  # 
  # @return [Array<Array>] options for an aircraft family select box
  def self.family_select_options
    self.families.pluck(:manufacturer, :family_name, :id).sort_by{|af| [af[0].downcase,af[1].downcase]}.map{|af| [[af[0],af[1]].join(" "), af[2]]}
  end
  
  # Returns a nested array of families and types in a format ready for
  # +grouped_options_for_select+. Used for generating aircraft family/type select
  # boxes on the {FlightsController#new add} and {FlightsController#edit edit}
  # \{Flight} form.
  # 
  # @return [Array<Array>] options for an aircraft family/type select box
  def self.grouped_type_select_options
    types = self.types.map{|f| {family_id: f.parent_id, family_name: f.family_name, id: f.id}}.sort_by{|f| f[:family_name]}
    families = self.families.sort_by{|f| [f[:manufacturer].downcase, f[:family_name].downcase]}
    return families.map{|f| {f.id => {family_name: f.family_name, manufacturer: f.manufacturer}}}
      .reduce{|a,b| a.merge(b)}
      .map{|k,v| ["#{v[:manufacturer]} #{v[:family_name]} Family"].push(([{family_name: "Unknown type of #{v[:family_name]}", id: k}]+types.select{|t| t[:family_id] == k}).map{|t| [t[:family_name], t[:id]]})}
  end
  
  # Accepts a flyer, the viewing user, and date range, and returns all aircraft
  # families that had their first flight in this date range. Types are included
  # as part of their parent family and are not listed separately. Used on
  # \{FlightsController#show_date_range} to highlight new aircraft families.
  #
  # @param flyer [User] the {User} whose flights should be searched
  # @param current_user [User, nil] the {User} viewing the flights
  # @param date_range [Range<Date>] the date range to search
  # @return [Array<Integer>] an array of AircraftFamily IDs
  def self.new_in_date_range(flyer, current_user, date_range)
    flights = flyer.flights(current_user).reorder(nil)
    first_flights = flights.joins(:aircraft_family).select(:aircraft_family_id, :parent_id, :departure_date).where.not(aircraft_family_id: nil).group(:aircraft_family_id, :parent_id).minimum(:departure_date)
    family_first_flights = first_flights.map{|k,v| {(k[1]||k[0]) => v}}
      .reduce{|a,b| a.merge(b){|k,oldval,newval| [oldval,newval].min}}
    return family_first_flights.select{|k,v| date_range.include?(v)}.map{|k,v| k}.sort
  end
  
  protected
  
  # Capitalizes form fields before saving them to the database.
  #
  # @return [Hash]
  def capitalize_codes
    CAPS_ATTRS.each { |attr| self[attr] = self[attr].upcase if !self[attr].blank? }
  end

end
