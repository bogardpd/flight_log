###############################################################################
# Defines a boarding pass using Apple's PassKit Package (PKPass) format.      #
###############################################################################

class PKPass < ApplicationRecord
  after_initialize :set_values
  
  validates :serial_number, :presence => true
  
  def create_or_update(pass, date)
    
  end
  
  # Returns the pass's barcode string
  def barcode
    if @pass.dig('barcode')
      return @pass.dig('barcode', 'message')
    else
      return @pass.dig('barcodes', 'message')
    end
  end
  
  protected
  
    def set_values
      @pass = JSON.parse(self.pass_json)
      self.assign_attributes({:serial_number => @pass.dig('serialNumber')})
    end

end
