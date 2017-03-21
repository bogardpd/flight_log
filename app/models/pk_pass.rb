###############################################################################
# Defines a boarding pass using Apple's PassKit Package (PKPass) format.      #
###############################################################################

class PKPass < ApplicationRecord
  after_initialize :set_values
  
  validates :serial_number, :presence => true, :uniqueness => true
  validates :pass_json, :presence => true
  
  # Returns the pass's barcode string
  def barcode
    if @pass.dig('barcode')
      return @pass.dig('barcode', 'message')
    else
      return @pass.dig('barcodes', 'message')
    end
  end
  
  # Returns a BoardingPass based on the PKPass's barcode field
  def bcbp
    return BoardingPass.new(barcode)
  end
  
  # Returns an array of hashes of summary details for all boarding passes.
  def self.pass_summary_list
    PKPass.all.map{|pass|
      fields = BoardingPass.new(pass.barcode, interpretations: false).summary_fields
      fields.store(:date, Time.parse(JSON.parse(pass.pass_json)["relevantDate"]))
      fields.store(:id, pass.id)
      fields
    }.sort_by{|h| h[:date]}
  end
  
  protected
  
    def set_values
      @pass = JSON.parse(self.pass_json)
      self.assign_attributes({:serial_number => @pass.dig('serialNumber')})
    end

end
