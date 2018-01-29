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
  
  # Returns a FlightAware FlightXML hash (as described in self.flight_xml) for
  # this particular pass
  def flight_xml
    pass_data = form_values
    airline = Airline.convert_iata_to_icao(pass_data[:airline_iata])
    flight_number = pass_data[:flight_number]
    departure_time = pass_data[:departure_utc]
    return nil if airline.nil? || flight_number.nil? || departure_time.nil?
    return PKPass.flight_xml(airline, flight_number, departure_time)
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
            
    return fields
  end
  
  # Accepts an airline string, a flight number string, and a departure time
  # and returns a hash containing aircraft type (ICAO), tail number, and
  # operator (ICAO). Airline can be ICAO or IATA, but if IATA it may not contain
  # a number (B6) and must then be converted to ICAO (JBU).
  def self.flight_xml(airline, flight_number, departure_time)
    begin
      client = Savon.client(wsdl: "https://flightxml.flightaware.com/soap/FlightXML2/wsdl", basic_auth: [ENV["FLIGHTAWARE_USERNAME"], ENV["FLIGHTAWARE_API_KEY"]])
      
      flight_id = client.call(:get_flight_id, message: {
        ident: [airline,flight_number].join,
        departure_time: departure_time.to_i
        }).to_hash[:get_flight_id_results][:get_flight_id_result]
        
      flight_info_ex = client.call(:flight_info_ex, message: {
        ident: flight_id,
        how_many: 1,
        offset: 0
        }).to_hash[:flight_info_ex_results][:flight_info_ex_result][:flights]
      
      airline_flight_info = client.call(:airline_flight_info, message: {
        fa_flight_i_d: flight_id
        }).to_hash[:airline_flight_info_results][:airline_flight_info_result]
      
      output = {
        aircraft_type: flight_info_ex[:aircrafttype],
        tail_number: airline_flight_info[:tailnumber],
        operator: flight_id[0,3],
        codeshares: airline_flight_info[:codeshares]
      }
      return output
    rescue
      return nil
    end
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
