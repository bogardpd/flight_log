class Flight < ActiveRecord::Base
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
  
  default_scope { order('flights.departure_utc') } # New flight default origin depends on this sort
  scope :visitor, -> {
    joins(:trip).
    where('hidden = FALSE')
  }
  
  def airline_icon_path
    image_location = "flight_log/airline_icons/" + self.airline.downcase.gsub(/\s+/, '-').gsub(/[^a-z0-9_-]/, '').squeeze('-') + ".png"
    if File.exist?("#{Rails.root}/public/images/#{image_location}")
      image_location
    else
      "flight_log/airline_icons/unknown-airline.png"
    end
  end
  
  def self.tail_country(tail_number)
    case tail_number.upcase
    when /^N[1-9]((\d{0,4})|(\d{0,3}[A-HJ-NP-Z])|(\d{0,2}[A-HJ-NP-Z]{2}))$/
      return "United States"
    when /^VH-[A-Z]{3}$/
      return "Australia"
    when /^C-[FGI][A-Z]{3}$/
      return "Canada"
    when /^B-((1[5-9]\d{2})|([2-9]\d{3}))$/
      return "China"
    when /^F-[A-Z]{4}$/
      return "France"
    when /^D-(([A-CE-IK-O][A-Z]{3})|(\d{4}))$/
      return "Germany"
    when /^9G-[A-Z]{3}$/
      return "Ghana"
    when /^SX-[A-Z]{3}$/
      return "Greece"
    when /^B-[HKL][A-Z]{2}$/
      return "Hong Kong"
    when /^TF-(([A-Z]{3})|([1-9]\d{2}))$/
      return "Iceland"
    when /^VT-[A-Z]{3}$/
      return "India"
    when /^4X-[A-Z]{3}$/
      return "Israel"
    when /^JA((\d{4})|(\d{3}[A-Z])|(\d{2}[A-Z]{2})|(A\d{3}))$/
      return "Japan"
    when /^JY-[A-Z]{3}$/
      return "Jordan"
    when /^9M-[A-Z]{3}$/
      return "Malaysia"
    when /^PH-(([A-Z]{3})|(1[A-Z]{2})|(\d[A-Z]\d)|([1-9]\d{2,3}))$/
      return "Netherlands"
    when /^ZK-[A-Z]{3}$/
      return "New Zealand"
    when /^9V-[A-Z]{3}$/
      return "Singapore"
    when /^B-((\d(0\d{3}|1[0-4]\d{2}))|([1-9]\d{4}))$/
      return "Taiwan"
    when /^HS-[A-Z]{3}$/
      return "Thailand"
    when /^UR-(([A-Z]{3,4})|([1-9]\d{4}))$/
      return "Ukraine"
    when /^A6-[A-Z]{3}$/
      return "United Arab Emirates"
    when /^G-(([A-Z]{4})|(\d{1,2}-\d{1,2}))$/
      return "United Kingdom"
    else
      return nil
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
