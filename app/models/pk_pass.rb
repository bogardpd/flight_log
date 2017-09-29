###############################################################################
# Defines a boarding pass using Apple's PassKit Package (PKPass) format.      #
###############################################################################

class PKPass < ApplicationRecord
  after_initialize :set_values
  before_create :check_for_existing_flight
  
  validates :serial_number, :presence => true, :uniqueness => true
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
    output = Hash.new
    data = BoardingPass.new(barcode, interpretations: false).data
    output.store(:serial_number, serial_number)
    output.store(:origin_airport_iata, data.dig(:repeated, 0, :mandatory, 26, :raw))
    output.store(:destination_airport_iata, data.dig(:repeated, 0, :mandatory, 38, :raw))
    rel_date = @pass.dig("relevantDate")
    if rel_date.present?
      begin
        output.store(:departure_date, Date.parse(rel_date))
        output.store(:departure_utc, Time.parse(rel_date).utc)
      rescue ArgumentError
      end
    end
    airline = data.dig(:repeated, 0, :mandatory, 42, :raw)&.strip
    if airline.present?
      output.store(:airline_iata, airline)
      bp_issuer = data.dig(:unique, :conditional, 21, :raw)&.strip
      marketing_carrier = data.dig(:repeated, 0, :conditional, 19, :raw)&.strip
      if (bp_issuer.present? && airline != bp_issuer)
        output.store(:codeshare_airline_iata, bp_issuer)
      elsif (marketing_carrier.present? && airline != marketing_carrier)
        output.store(:codeshare_airline_iata, marketing_carrier)
      end
      begin
        airline_compartments = JSON.parse(File.read("app/assets/json/airline_compartments.json"))
        compartment_code = data.dig(:repeated, 0, :mandatory, 71, :raw)
        if compartment_code.present?
          travel_class = airline_compartments.dig(airline, compartment_code, "name")
          output.store(:travel_class, TravelClass.get_class_id(travel_class))
        end
      rescue Errno::ENOENT
      end
    end
    output.store(:flight_number, data.dig(:repeated, 0, :mandatory, 43, :raw)&.strip&.gsub(/^0*/, ""))
    output.store(:boarding_pass_data, barcode)
    return output
  end
  
  # Accepts a Flight, and returns a hash of flight values compared to boarding
  # pass values. If any new pass values joined to another table aren't found,
  # they're stored in a :lookup key so that they can be added later.
  def updated_values(flight, include_flightxml=false)
    fields = Hash.new
    pass_data = form_values
        
    # Origin Airport
    fields[:origin_airport_id] = Hash.new
    fields[:origin_airport_id][:label] = "Origin Airport"
    if flight.origin_airport
      fields[:origin_airport_id][:current_value] = flight.origin_airport.id
      fields[:origin_airport_id][:current_text] = {text: flight.origin_airport.city, code: flight.origin_airport.iata_code}
    end
    pass_airport = Airport.find_by(iata_code: pass_data[:origin_airport_iata])
    if pass_airport
      fields[:origin_airport_id][:pass_value] = pass_airport.id
      fields[:origin_airport_id][:pass_text] = {text: pass_airport.city, code: pass_airport.iata_code}
    else
      fields[:origin_airport_id][:lookup] = {type: :airport, iata_code: pass_data[:origin_airport_iata]}
    end
    
    # Destination Airport
    fields[:destination_airport_id] = Hash.new
    fields[:destination_airport_id][:label] = "Destination Airport"
    if flight.destination_airport
      fields[:destination_airport_id][:current_value] = flight.destination_airport.id
      fields[:destination_airport_id][:current_text] = {text: flight.destination_airport.city, code: flight.destination_airport.iata_code}
    end
    pass_airport = Airport.find_by(iata_code: pass_data[:destination_airport_iata])
    if pass_airport
      fields[:destination_airport_id][:pass_value] = pass_airport.id
      fields[:destination_airport_id][:pass_text] = {text: pass_airport.city, code: pass_airport.iata_code}
    else
      fields[:destination_airport_id][:lookup] = {type: :airport, iata_code: pass_data[:destination_airport_iata]}
    end
    
    # Departure Date (Local)
    fields[:departure_date] = Hash.new
    fields[:departure_date][:label] = "Departure Date (Local)"
    if flight.departure_date
      fields[:departure_date][:current_value] = flight.departure_date
      fields[:departure_date][:current_text] = {text: flight.departure_date.strftime("%a, %-d %b %Y")}
    end
    if pass_data[:departure_date]
      fields[:departure_date][:pass_value] = pass_data[:departure_date]
      fields[:departure_date][:pass_text] = {text: pass_data[:departure_date].strftime("%a, %-d %b %Y")}
    end
    
    # Departure (UTC)
    fields[:departure_utc] = Hash.new
    fields[:departure_utc][:label] = "Departure (UTC)"
    if flight.departure_utc
      fields[:departure_utc][:current_value] = flight.departure_utc
      fields[:departure_utc][:current_text] = {text: flight.departure_utc.strftime("%a, %-d %b %Y %R %Z")}
    end
    if pass_data[:departure_utc]
      fields[:departure_utc][:pass_value] = pass_data[:departure_utc]
      fields[:departure_utc][:pass_text] = {text: pass_data[:departure_utc].strftime("%a, %-d %b %Y %R %Z")}
    end
    
    # Airline
    fields[:airline_id] = Hash.new
    fields[:airline_id][:label] = "Airline"
    if flight.airline
      fields[:airline_id][:current_value] = flight.airline.id
      fields[:airline_id][:current_text] = {text: flight.airline.airline_name, code: flight.airline.iata_airline_code}
    end
    pass_airline = Airline.find_by(iata_airline_code: pass_data[:airline_iata])
    if pass_airline
      fields[:airline_id][:pass_value] = pass_airline.id
      fields[:airline_id][:pass_text] = {text: pass_airline.airline_name, code: pass_airline.iata_airline_code}
    else
      fields[:airline_id][:lookup] = {type: :airline, iata_code: pass_data[:airline_iata]}
    end
    
    # Flight Number
    fields[:flight_number] = Hash.new
    fields[:flight_number][:label] = "Flight Number"
    if flight.flight_number
      fields[:flight_number][:current_value] = flight.flight_number
      fields[:flight_number][:current_text] = {text: flight.flight_number}
    end
    if pass_data[:flight_number]
      fields[:flight_number][:pass_value] = pass_data[:flight_number]
      fields[:flight_number][:pass_text] = {text: pass_data[:flight_number]}
    end
    
    # Codeshare Airline
    fields[:codeshare_airline_id] = Hash.new
    fields[:codeshare_airline_id][:label] = "Codeshare Airline"
    if flight.codeshare_airline
      fields[:codeshare_airline_id][:current_value] = flight.codeshare_airline.id
      fields[:codeshare_airline_id][:current_text] = {text: flight.codeshare_airline.airline_name, code: flight.codeshare_airline.iata_airline_code}
    end
    
    if pass_data[:codeshare_airline_iata]
      pass_airline = Airline.find_by(iata_airline_code: pass_data[:codeshare_airline_iata])
      if pass_airline
        fields[:codeshare_airline_id][:pass_value] = pass_airline.id
        fields[:codeshare_airline_id][:pass_text] = {text: pass_airline.airline_name, code: pass_airline.iata_airline_code}
      else
        fields[:codeshare_airline_id][:lookup] = {type: :airline, iata_code: pass_data[:codeshare_airline_iata]}
      end
    end
    
    # Travel Class
    fields[:travel_class] = Hash.new
    fields[:travel_class][:label] = "Travel Class"
    if flight.travel_class
      fields[:travel_class][:current_value] = flight.travel_class
      fields[:travel_class][:current_text] = {text: TravelClass.list[flight.travel_class], code: flight.travel_class}
    end
    if pass_data[:travel_class]
      fields[:travel_class][:pass_value] = pass_data[:travel_class]
      fields[:travel_class][:pass_text] = {text: TravelClass.list[pass_data[:travel_class]], code: pass_data[:travel_class]}
    end
    
    # Boarding Pass
    fields[:boarding_pass_data] = Hash.new
    fields[:boarding_pass_data][:label] = "Boarding Pass Data"
    if flight.boarding_pass_data
      fields[:boarding_pass_data][:current_value] = flight.boarding_pass_data
      fields[:boarding_pass_data][:current_text] = {code_block: flight.boarding_pass_data}
    end
    if pass_data[:boarding_pass_data]
      fields[:boarding_pass_data][:pass_value] = pass_data[:boarding_pass_data]
      fields[:boarding_pass_data][:pass_text] = {code_block: pass_data[:boarding_pass_data]}
    end
    
    # FlightXML fields:
    if include_flightxml
      flight_xml_data = flight_xml
      
      if flight_xml
      
        # Codeshare Flight Number
        if pass_data[:codeshare_airline_iata]
          codeshare_flight = flight_xml_data[:codeshares].select{|cs| cs[0,3] == Airline.convert_iata_to_icao(pass_data[:codeshare_airline_iata])}.first
          if codeshare_flight
            fields[:codeshare_flight_number] = Hash.new
            fields[:codeshare_flight_number][:label] = "Codeshare Flight Number"
            fields[:codeshare_flight_number][:pass_value] = codeshare_flight[3..-1]
            fields[:codeshare_flight_number][:pass_text] = {text: codeshare_flight[3..-1]}
          end
        end
      
        # Aircraft Family/Type
        fields[:aircraft_family_id] = Hash.new
        fields[:aircraft_family_id][:label] = "Aircraft Type"
        if flight_xml_data[:aircraft_type]
          pass_aircraft_type = AircraftFamily.find_id_from_code(flight_xml_data[:aircraft_type])
          if pass_aircraft_type.present?
            fields[:aircraft_family_id][:pass_value] = pass_aircraft_type
            fields[:aircraft_family_id][:pass_text] = {code: flight_xml_data[:aircraft_type]}
          else
            fields[:aircraft_family_id][:lookup] = {type: :aircraft, icao_code: flight_xml_data[:aircraft_type]}
          end
        end
      
        # Tail Number
        fields[:tail_number] = Hash.new
        fields[:tail_number][:label] = "Tail Number"
        if flight_xml_data[:tail_number]
          fields[:tail_number][:pass_value] = flight_xml_data[:tail_number]
          fields[:tail_number][:pass_text] = {text: flight_xml_data[:tail_number]}
        end
      
        # Operator
        fields[:operator_id] = Hash.new
        fields[:operator_id][:label] = "Operator"
        if flight_xml_data[:operator]
          pass_operator = Airline.find_by(icao_airline_code: flight_xml_data[:operator])
          if pass_operator.present?
            fields[:operator_id][:pass_value] = pass_operator.id
            fields[:operator_id][:pass_text] = {text: pass_operator.airline_name, code: flight_xml_data[:operator]}
          else
            fields[:operator_id][:lookup] = {type: :airline, icao_code: flight_xml_data[:operator]}
          end
        end
      else
        fields[:error] = Hash.new
        fields[:error][:label] = "Could not find flight data on FlightAware; you will have to manually enter some fields. (Searched for #{Airline.convert_iata_to_icao(pass_data[:airline_iata])} #{pass_data[:flight_number]} #{pass_data[:departure_utc]})"
      end
      
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
  
  # Returns a hash of Flights with updated boarding passes, with flight ids as the keys and pass ids as the values
  def self.flights_with_updated_passes
    return PKPass.where.not(flight_id: nil).map{|pass| {pass.flight_id => pass.id}}.reduce({}, :merge)
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
        fields.store(:date, Time.parse(json_data["expiration_date"]-1.day))
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
    
    def check_for_existing_flight
      associated_flight = Flight.where(pass_serial_number: self.serial_number)
      if associated_flight.any?
        self.assign_attributes({flight_id: associated_flight.first.id})
      end
    end

end
