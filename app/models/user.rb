class User < ActiveRecord::Base
  attr_accessible :name, :password, :password_confirmation
  has_secure_password
  
  before_save :create_remember_token
  
  validates :name, :presence => true, :uniqueness => true, :length => { :maximum => 50 }
  validates :password, :presence => true, :length => { :minimum => 6 }
  validates :password_confirmation, :presence => true
  
  private
    
    def create_remember_token
      self.remember_token = SecureRandom.hex
    end
    
end
