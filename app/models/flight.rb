class Flight < ApplicationRecord
  belongs_to :trip
  belongs_to :origin_airport, :class_name => "Airport"
  belongs_to :destination_airport, :class_name => "Airport"
  belongs_to :airline
  belongs_to :aircraft_family
  belongs_to :operator, :class_name => "Airline"
  belongs_to :codeshare_airline, :class_name => "Airline"
    
  # Returns a hash containing the AircraftFamily for the flight's family, and
  # the AircraftFamily for the flight's subtype if available
  def aircraft_family_and_type
    return nil unless aircraft_family
    return {family: aircraft_family} if aircraft_family.is_family?
    return {family: aircraft_family.parent, type: aircraft_family}
  end
  
  NULL_ATTRS = %w( flight_number aircraft_name tail_number travel_class comment fleet_number boarding_pass_data )
  STRIP_ATTRS = %w( operator fleet_number aircraft_family aircraft_name tail_number )
  CAPS_ATTRS = %w( tail_number )
  
  before_save :nil_if_blank
  before_save :strip_blanks
  before_save :capitalize
  
  validates :origin_airport_id, :presence => true
  validates :destination_airport_id, :presence => true
  validates :trip_id, :presence => true
  validates :trip_section, :presence => true
  validates :departure_date, :presence => true
  validates :departure_utc, :presence => true
  validates :airline_id, presence: true
  validates :travel_class, :inclusion => { in: TravelClass.list.keys, message: "%{value} is not a valid travel class" }, :allow_nil => true, :allow_blank => true
  
  scope :chronological, -> {
    order("flights.departure_utc")
  }  
    
  protected
  
  def nil_if_blank
    NULL_ATTRS.each { |attr| self[attr] = nil if self[attr].blank? }
  end
  
  def strip_blanks
    STRIP_ATTRS.each { |attr| self[attr] = self[attr].strip if !self[attr].blank? }
  end
  
  def capitalize
    CAPS_ATTRS.each { |attr| self[attr] = self[attr].upcase if !self[attr].blank? }
  end
  
  # For a given flight collection, return a hash with years as the keys, and
  # hashes of counts of business, mixed, and personal flights as the values.
  # by_year[2009] = {business: 35, mixed: 4, personal: 7}
  # Years with no flights that are between the earliest and latest flight will
  # be included, with zeroes in the values.
  def self.by_year
    # Create hash ranging from earliest to latest years (default all values to zero):
    summary = Hash.new
    if self.year_range
      self.year_range.each do |year|
        summary[year] = {business: 0, mixed: 0, personal: 0, undefined: 0}
      end
    end
    
    # Loop through all flights (with year and flight.trip.purpose selected and increment hash):
    flights = self.select("departure_date, trips.purpose AS purpose").joins("LEFT OUTER JOIN trips ON trips.id = flights.trip_id")
    flights.each do |flight|
      purpose = flight.purpose ? flight.purpose.to_sym : :undefined
      summary[flight.departure_date.year][purpose] += 1
    end
    
    return summary
  end
  
  # Formats a date string.
  def self.format_date(input_date)
    return nil unless input_date.present?
    input_date.strftime("%e %b %Y")
  end
  
  # Accepts an optional PKPass object and/or FlightXML faFlightID string, and
  # returns a hash of all form fields with known values.
  def self.lookup_form_fields(pk_pass: nil, fa_flight_id: nil)
    fields = Hash.new
    
    # Guess trip section:
    #TODO
    
    # Look up fields from PK Pass, if any:
    if pk_pass
      fields[:pk_pass_id] = pk_pass.id
      pass_data = pk_pass.form_values
      fields.merge!(pass_data) if pass_data
    end
    
    # Look up fields on FlightAware, if known:
    if fa_flight_id
      fields[:fa_flight_id] = fa_flight_id
      #TODO
    end
    
    return fields
  end
  
  # For a given flight collection, return a range of the years that contain
  # flights.
  def self.year_range
    return nil unless self.any?
    sorted = self.chronological
    return sorted.first.departure_date.year..sorted.last.departure_date.year
  end
  
  # For a given flight collection, return an array of years containing flights.
  def self.years_with_flights
    flights = self.chronological
    years_with_flights = Array.new
    flights.each do |flight|
      years_with_flights.push(flight.departure_date.year)
    end
    return years_with_flights.uniq
  end
  
end
