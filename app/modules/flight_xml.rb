# Used to interact with FlightAware's FlightXML API.

module FlightXML
  
  # Defines the Savon client to connect to the FlightXML API.
  def self.client
    return Savon.client(wsdl: "https://flightxml.flightaware.com/soap/FlightXML2/wsdl", basic_auth: [ENV["FLIGHTAWARE_USERNAME"], ENV["FLIGHTAWARE_API_KEY"]])
  end
  
  # Accepts an airport ICAO string, and returns its TZInfo Timezone
  def self.airport_timezone(airport_icao)
    begin
      tz = client.call(:airport_info, message: {
        airport_code: airport_icao
        }).to_hash[:airport_info_results][:airport_info_result][:timezone]
      return TZInfo::Timezone.get(tz.tr(":", ""))
    rescue
      return nil
    end
  end
  
  # Accepts an array of airport ICAO code strings, and returns a hash of each
  # airport code and its TZInfo Timezone.
  def self.airport_timezones(airport_icao_array)
    airport_icao_array.map{|icao| { icao => airport_timezone(icao) }}.reduce(:merge)
  end
  
  # Accepts an airline string and a flight number string and returns
  # an array of flights.
  # Airline can be ICAO or IATA, but if IATA it may not contain
  # a number (B6) and must then be converted to ICAO (JBU).
  def self.flight_lookup(airline, flight_number)
    begin
     
      flights = client.call(:flight_info_ex, message: {
        ident: [airline,flight_number].join,
        how_many: 15,
        offset: 0
        }).to_hash[:flight_info_ex_results][:flight_info_ex_result][:flights]
        
      
      return flights
    rescue
      return nil
    end
    
  end
  
end