class User < ActiveRecord::Base
  has_secure_password
  
  before_save :create_remember_token
  
  validates :name, :presence => true, :uniqueness => true, :length => { :maximum => 50 }
  validates :password, :presence => true, :length => { :minimum => 6 }
  validates :password_confirmation, :presence => true
  validates :email, :presence => true
  
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
