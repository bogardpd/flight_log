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
  
  def self.tail_country(tail_number)
    case tail_number.upcase
    when /^N(([1-9]\d{0,2}[A-HJ-NP-Z]{0,2})|([1-9]\d{0,3}[A-HJ-NP-Z]{0,1})|([1-9]\d{0,4}))$/
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
    
=begin    
    tail = tail_number.upcase
        
    if tail.start_with?('N')
      return "United States"
    elsif tail.start_with?('4X-')
      return "Israel"
    elsif tail.start_with?('9G-')
      return "Ghana"
    elsif tail.start_with?('9M-')
      return "Malaysia"
    elsif tail.start_with?('9V-')
      return "Singapore"
    elsif tail.start_with?('A6-')
      return "United Arab Emirates"
    elsif tail.start_with?('B-')
      if tail.start_with?('B-H','B-K','B-L')
        return "Hong Kong"
      elsif tail.length == 6
        return "China"
      elsif tail.length == 7
        return "Taiwan"
      else
        return nil
      end
    elsif tail.start_with?('C-')
      return "Canada"
    elsif tail.start_with?('D-')
      return "Germany"
    elsif tail.start_with?('F-')
      return "France"
    elsif tail.start_with?('G-')
      return "United Kingdom"
    elsif tail.start_with?('HS-')
      return "Thailand"
    elsif tail.start_with?('JA')
      return "Japan"
    elsif tail.start_with?('JY-')
      return "Jordan"
    elsif tail.start_with?('PH-')
      return "The Netherlands"
    elsif tail.start_with?('UR-')
      return "Ukraine"
    elsif tail.start_with?('VH-')
      return "Australia"
    elsif tail.start_with?('VT-')
      return "India"
    elsif tail.start_with?('ZK-','ZL-','ZM-')
      return "New Zealand"
    else
      return nil
    end
=end      
      
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
