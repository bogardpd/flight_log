class Flight < ActiveRecord::Base
  attr_accessible :aircraft_family, :aircraft_variant, :airline, :codeshare_airline, :codeshare_flight_number, :comment, :departure_date, :departure_utc, :destination_airport_id, :fleet_number, :flight_number, :operator, :origin_airport_id, :tail_number, :travel_class, :trip_id, :trip_section
  belongs_to :trip
  belongs_to :origin_airport, :class_name => 'Airport'
  belongs_to :destination_airport, :class_name => 'Airport'
  
  NULL_ATTRS = %w( flight_number aircraft_family aircraft_variant tail_number travel_class comment operator fleet_number codeshare_airline )
  STRIP_ATTRS = %w( airline codeshare_airline operator fleet_number aircraft_family aircraft_variant tail_number )
  
  before_save :nil_if_blank
  before_save :strip_blanks
  
  validates :origin_airport_id, :presence => true
  validates :destination_airport_id, :presence => true
  validates :trip_id, :presence => true
  validates :trip_section, :presence => true
  validates :departure_date, :presence => true
  validates :departure_utc, :presence => true
  validates :airline, :presence => true
  validates :travel_class, :inclusion => { :in => %w(Economy Business First), :message => "%{value} is not a valid travel class" }, :allow_nil => true, :allow_blank => true
  
  default_scope :order => 'flights.departure_utc' # New flight default origin depends on this sort
  scope :visitor, joins(:trip).where("hidden = FALSE")
  
  def airline_icon_path
    image_location = "flight_log/airline_icons/" + self.airline.downcase.gsub(/\s+/, '-').gsub(/[^a-z0-9_-]/, '').squeeze('-') + ".png"
    if File.exist?("#{Rails.root}/public/images/#{image_location}")
      image_location
    else
      "flight_log/airline_icons/unknown-airline.png"
    end
  end
  
  protected
  
  def nil_if_blank
    NULL_ATTRS.each { |attr| self[attr] = nil if self[attr].blank? }
  end
  
  def strip_blanks
    STRIP_ATTRS.each { |attr| self[attr] = self[attr].strip if !self[attr].blank? }
  end
  
  def self.aircraft_first_flight(aircraft_family)
    return Flight.where(:aircraft_family => aircraft_family).first(:order => 'departure_date ASC').departure_date
  end
  
  def self.airline_first_flight(airline)
    return Flight.where(:airline => airline).first(:order => 'departure_date ASC').departure_date
  end
  
  def self.airport_first_visit(airport_id)
    return Flight.where("origin_airport_id = ? OR destination_airport_id = ?", airport_id, airport_id).first(:order => 'departure_date ASC').departure_date
  end
  
end
