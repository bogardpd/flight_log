class PKPass < ApplicationRecord
  after_initialize :set_json
  
  validates :serial_number, :presence => true
  
  def create_or_update(pass, date)
    
  end
  
  protected
  
    def set_json
    
    end

end
