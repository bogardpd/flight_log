class User < ApplicationRecord
  has_secure_password
  has_many :trips, dependent: :destroy
  
  before_save :create_remember_token
  
  validates :name, :presence => true, :uniqueness => true, :length => { :maximum => 50 }
  validates :password, :presence => true, :length => { :minimum => 6 }
  validates :password_confirmation, :presence => true
  validates :email, :presence => true
  
  # Returns both emails associated with a user.
  def all_emails
    return [self.email, self.alternate_email]
  end
  
  # Returns all of this user's flights that viewing_user is allowed to see.
  # If the viewer is a visitor, viewing_user should be nil.
  def flights(viewing_user=nil)
    if self == viewing_user
      # The viewer is viewing their own flights, so get all trips.
      trip_ids = self.trips.pluck(:id)
    else
      # The viewer is viewing someone else's flights, so get trips which are not hidden.
      trip_ids = self.trips.where(hidden: false).pluck(:id)
    end
    return Flight.where(trip_id: trip_ids.sort)
  end
    
  # Returns the hash digest of the given string.
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end
  
  private
    
    def create_remember_token
      self.remember_token = SecureRandom.hex
    end
    
end
