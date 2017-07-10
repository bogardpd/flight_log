class Trip < ApplicationRecord
  has_many :flights, dependent: :destroy
  belongs_to :user
  
  validates :user_id, presence: true
  
  def self.purposes_list
    purposes = Hash.new
    purposes['business'] = 'Business'
    purposes['mixed'] = 'Mixed'
    purposes['personal'] = 'Personal'
    return purposes
  end
  
  # Returns a collection of trips with departure dates (filtered by visitor if appropriate)
  def self.with_departure_dates(flyer, current_user)
    if flyer == current_user
      trips = Trip.find_by_sql(["SELECT flights.trip_id, trips.id, trips.name, trips.hidden, MIN(flights.departure_date) AS departure_date FROM flights JOIN trips ON flights.trip_id = trips.id WHERE trips.user_id = 1 GROUP BY flights.trip_id, trips.id, trips.name, trips.hidden ORDER BY departure_date", flyer.id])
    else
      trips = Trip.find_by_sql(["SELECT flights.trip_id, trips.id, trips.name, trips.hidden, MIN(flights.departure_date) AS departure_date FROM flights JOIN trips ON flights.trip_id = trips.id WHERE trips.user_id = ? AND trips.hidden = false GROUP BY flights.trip_id, trips.id, trips.name, trips.hidden ORDER BY departure_date", flyer.id])
    end
  
    return trips
  end
  
  def self.with_no_flights
    return Trip.where('id not in (?)',Trip.distinct.joins(:flights).select("trips.id"))
  end
  
  NULL_ATTRS = %w( comment )
  before_save :nil_if_blank
  
  validates :name, :presence => true
  
  scope :visitor, -> { where('hidden = FALSE') }
  
  protected
  
  def nil_if_blank
    NULL_ATTRS.each { |attr| self[attr] = nil if self[attr].blank? }
  end
end
