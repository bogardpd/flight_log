# Defines a model for users.
# 
# Since multi-user functionality is not yet implemented in this application,
# this model is only used to support a single user and has very little
# implemented functionality at this time. If multi-user functionality is added,
# this model will require substantial modification.
class User < ApplicationRecord
  has_secure_password
  has_many :trips, dependent: :destroy
  
  before_save :create_remember_token
  before_create :create_api_key
  
  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :password, presence: true, length: { minimum: 6 }
  validates :password_confirmation, presence: true
  validates :email, presence: true
  
  # Returns both email addresses associated with this User. Used by
  # {ApplicationController#check_email_for_boarding_passes} to match received
  # emails to a User.
  # 
  # @return [Array<String>] email addresses
  def all_emails
    return [self.email, self.alternate_email]
  end

  # Returns a hash of the user's flight count and distances by trip purpose for
  # each year.
  #
  # @param viewing_user [User] the {User} (or visitor if nil) viewing the flights
  # @return [Hash] the user's annual flight summary
  # @example
  #   User.annual_flight_summary => {
  #     2018 => {
  #       count: {business: 0, mixed: 0, personal: 0, undefined: 0},
  #       distance_mi: {business: 0, mixed: 0, personal: 0, undefined: 0},
  #     }
  #   }
  def annual_flight_summary(viewing_user=nil)
    flights = self.flights(viewing_user)
    route_distances = flights.route_distances
    trip_ids = flights.map{|f| f.trip_id}.uniq
    purposes = Trip.where(id: trip_ids).pluck(:id, :purpose).to_h
    summary = Hash.new
    if flights.year_range
      flights.year_range.each do |year|
        summary[year] = {
          count: {business: 0, mixed: 0, personal: 0, undefined: 0},
          distance_mi: {business: 0, mixed: 0, personal: 0, undefined: 0},
        }
      end
    end

    # Loop through all flights and add to the summary.
    flights.each do |flight|
      year = flight.departure_date.year
      purpose = purposes.dig(flight.trip_id).nil? ? :undefined : purposes[flight.trip_id].to_sym
      distance = route_distances[[flight.origin_airport_id,flight.destination_airport_id].sort] || 0
      summary[year][:count][purpose] += 1
      summary[year][:distance_mi][purpose] += distance
    end
    return summary
  end
  
  # Returns all of this User's flights that the viewing user/visitor has
  # permission to see.
  #
  # @param viewing_user [User] the {User} (or visitor if nil) viewing the flights
  # @return [Array<Flight>] a collection of flights
  def flights(viewing_user=nil)
    if self == viewing_user
      # The viewer is viewing their own flights, so get all trips.
      return Flight.joins(:trip).where(trips: {user_id: self.id}).chronological
    else
      # The viewer is viewing someone else's flights, so get trips which are not hidden.
      return Flight.joins(:trip).where(trips: {user_id: self.id, hidden: false}).chronological
    end
  end
    
  # Returns the hash digest of the given string. Used for hashing User passwords.
  # 
  # @param string [String] the password to hash
  # @return [String] a hashed password
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end
  
  private
  
  # Creates a token for storing in session cookies to remember a user.
  # 
  # @return [String] a token
  def create_remember_token
    self.remember_token = SecureRandom.hex
  end

  # Creates an API key for the user.
  # 
  # @return [String] an API key
  def create_api_key
    self.api_key = SecureRandom.hex
  end
    
end
