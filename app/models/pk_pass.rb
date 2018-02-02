###############################################################################
# Defines a boarding pass using Apple's PassKit Package (PKPass) format.      #
###############################################################################

class PKPass < ApplicationRecord
  after_initialize :set_values
  
  validates :pass_json, :presence => true
  
  # Returns the pass's barcode string
  def barcode
    if @pass.dig("barcodes")
      return @pass.dig("barcodes", 0, "message")
    else
      return @pass.dig("barcode", "message")
    end
  end
  
  # Returns a BoardingPass based on the PKPass's barcode field
  def bcbp
    return BoardingPass.new(barcode)
  end
  
  # Returns a hash of form default values for this pass
  def form_values
    fields = Hash.new
    
    fields.store(:boarding_pass_data, barcode)
    
    rel_date = @pass.dig("relevantDate")
    if rel_date.present?
      begin
        fields.store(:departure_date, Date.parse(rel_date))
        fields.store(:departure_utc, Time.parse(rel_date).utc)
      rescue ArgumentError
      end
    end
    
    # Look up data from BCBP fields:
    pass = BoardingPass.new(barcode, interpretations: false)
    if pass.is_valid?
      fields.merge!(pass.form_values)
    end
    
    airline_icao = Airline.convert_iata_to_icao(fields[:airline_iata])
    if airline_icao && fields[:flight_number]
      fields.store(:ident, [airline_icao, fields[:flight_number]].join)
    end

    # Try to determine FlightXML faFlightID:
    flight_id = FlightXML.get_flight_id(fields[:ident], fields[:departure_utc])
    fields.store(:fa_flight_id, flight_id) if flight_id
            
    return fields
  end
  
  # Returns an array of hashes of summary details for all boarding passes
  # that are not yet associated with a flight.
  def self.pass_summary_list
    PKPass.where(flight_id: nil).map{|pass|
      fields = BoardingPass.new(pass.barcode, interpretations: false).summary_fields
      json_data = JSON.parse(pass.pass_json)
      if json_data["relevantDate"]
        fields.store(:date, Time.parse(json_data["relevantDate"]))
      elsif json_data["expirationDate"]
        fields.store(:date, Time.parse(json_data["expirationDate"]) - 1.day)
      else
        fields.store(:date, Time.now)
      end
      fields.store(:id, pass.id)
      fields
    }.sort_by{|h| h[:date]}
  end
  
  protected
  
    def set_values
      @pass = JSON.parse(self.pass_json)
      self.assign_attributes({:serial_number => [@pass.dig("passTypeIdentifier"),@pass.dig("serialNumber")].join(",")})
    end

end
