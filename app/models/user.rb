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
  
  validates :name, :presence => true, :uniqueness => true, :length => { :maximum => 50 }
  validates :password, :presence => true, :length => { :minimum => 6 }
  validates :password_confirmation, :presence => true
  validates :email, :presence => true
  
  # Returns both email addresses associated with this User. Used by
  # {ApplicationController#check_email_for_boarding_passes} to match received
  # emails to a User.
  # 
  # @return [Array<String>] email addresses
  def all_emails
    return [self.email, self.alternate_email]
  end
  
  # Returns all of this User's flights that the viewing user/visitor has
  # permission to see.
  #
  # @param viewing_user [User] the {User} (or visitor if nil) viewing the flights
  # @return [Array<Flight>] a collection of flights
  def flights(viewing_user=nil)
    if self == viewing_user
      # The viewer is viewing their own flights, so get all trips.
      trip_ids = self.trips.pluck(:id)
    else
      # The viewer is viewing someone else's flights, so get trips which are not hidden.
      trip_ids = self.trips.where(hidden: false).pluck(:id)
    end
    return Flight.where(trip_id: trip_ids.sort).order(:departure_utc)
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
    
end
