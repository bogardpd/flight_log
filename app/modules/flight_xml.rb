# Provides utilities for interacting with with FlightAware's FlightXML API.
#
# This is used to look up {Flight} data that couldn't be found from a
# {BoardingPass} or {PKPass} for the purposes of prepopulating the
# {FlightsController#new new flight} form. It's also used to look up {Airport}
# data when creating a {AirportsController#new new airport}.
#
# Note: Since FlightXML has its own database of flights, airports, and routes,
# when you see these terms in this documentation, it refers to FlightXML and
# not this applications models, unless it specifically links to {Flight},
# {Airport}, or {Route}.
#
# Uses the {http://savonrb.com/ Savon} gem as a SOAP client to interact with FlightXML. 
# 
# @see https://flightaware.com/commercial/flightxml/documentation2.rvt FlightXML 2.0 Documentation
# @see http://savonrb.com/ Savon
module FlightXML
  
  # The default error message to return if a FlightXML lookup failed.
  ERROR = "We couldn’t find your flight data on FlightAware. You will have to manually enter some fields."
  
  # Defines the Savon client to connect to the FlightXML API.
  #
  # @return [Savon::Client] a Savon client
  def self.client
    return Savon.client(wsdl: "https://flightxml.flightaware.com/soap/FlightXML2/wsdl", basic_auth: [Rails.application.credentials[:flightaware][:username], Rails.application.credentials[:flightaware][:api_key]])
  end
  
  # Looks up the latitude and longitude for an ICAO airport code.
  #
  # @param airport_icao [String] an ICAO airport code
  # @return [Array<Float>] latitude and longitude in decimal degrees
  def self.airport_coordinates(airport_icao)
    begin
      pos = client.call(:airport_info, message: {
        airport_code: airport_icao
        }).to_hash[:airport_info_results][:airport_info_result]
      return [pos[:latitude].to_f, pos[:longitude].to_f]
    rescue
      return nil
    end
  end
  
  # Looks up the timezone for an ICAO airport code.
  #
  # @param airport_icao [String] an ICAO airport code
  # @return [TZInfo::DataTimezone] a timezone
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
  
  # Looks up the timezones for multiple ICAO airport codes.
  #
  # @param airport_icao_array [Array<String>] ICAO airport codes
  # @return [Hash{String => TZInfo::DataTimezone}] ICAO keys and timezone values
  def self.airport_timezones(airport_icao_array)
    airport_icao_array.map{|icao| { icao => airport_timezone(icao) }}.reduce(:merge)
  end
  
  # Looks up flight data for flights matching a flight identifier string.
  #
  # A flight identifier is a string containing an airline code and a flight
  # number, with no space between them (e.g. AA1234 or UAL5678). The airline
  # can be ICAO or IATA, but IATA codes that contain numbers (e.g. B6) may not
  # be used (the ICAO code must then be used in these cases).
  #
  # Usually the multiple matching flights are the same flight number on
  # different days, but some airlines reuse a flight number multiple times per
  # day for different routes.
  #
  # @param ident [String] a flight identifier
  # @return [Array<Hash>] data for each matching flight
  def self.flight_lookup(ident)
    begin
      flights = client.call(:flight_info_ex, message: {
        ident: ident,
        how_many: 15,
        offset: 0
        }).to_hash[:flight_info_ex_results][:flight_info_ex_result][:flights]
      return Array.wrap(flights) # Ensure result is an array even if it's a single flight
    rescue
      return nil
    end
  end
  
  # Looks up flight data for a FlightXML fa_flight_id.
  # 
  # @param fa_flight_id [String] a FlightAware/FlightXML unique flight ID
  # @return [Hash] flight data
  def self.form_values(fa_flight_id)
    return nil unless fa_flight_id
    fields = Hash.new
    
    begin
      flight_info_ex = client.call(:flight_info_ex, message: {
        ident: fa_flight_id,
        how_many: 1,
        offset: 0
        }).to_hash[:flight_info_ex_results][:flight_info_ex_result][:flights]
      airline_flight_info = client.call(:airline_flight_info, message: {
        fa_flight_i_d: fa_flight_id
        }).to_hash[:airline_flight_info_results][:airline_flight_info_result]
    rescue
      return nil
    end
    
    fields.store(:origin_airport_icao, flight_info_ex[:origin]) if flight_info_ex[:origin]
    fields.store(:destination_airport_icao, flight_info_ex[:destination]) if flight_info_ex[:destination]
    fields.store(:aircraft_family_icao, flight_info_ex[:aircrafttype]) if flight_info_ex[:aircrafttype]
    
    operator_icao = flight_info_ex[:ident][0,3] if flight_info_ex[:ident]
    fields.store(:operator_icao, flight_info_ex[:ident][0,3]) if operator_icao
    
    fields.store(:departure_utc, Time.at(flight_info_ex[:filed_departuretime].to_i).utc) if flight_info_ex[:filed_departuretime]
    fields.store(:tail_number, airline_flight_info[:tailnumber]) if airline_flight_info[:tailnumber]
    
    return fields
  end
  
  # Accepts a FlightXML ident and a departure time, and returns a FlightXML ID.

  # Looks up a FlightXML unique flight ID for flights matching a flight
  # identifier string and UTC departure date/time.
  #
  # A flight identifier is a string containing an airline code and a flight
  # number, with no space between them (e.g. AA1234 or UAL5678). The airline
  # can be ICAO or IATA, but IATA codes that contain numbers (e.g. B6) may not
  # be used (the ICAO code must then be used in these cases).
  #
  # @param ident [String] a flight identifier
  # @param departure_utc [DateTime] a UTC departure time
  # @return [String] a FlightXML fa_flight_id
  def self.get_flight_id(ident, departure_utc)
    return nil unless ident && departure_utc
    
    begin
      flight_id = client.call(:get_flight_id, message: {
        ident: ident,
        departure_time: departure_utc.to_i
      })
      return flight_id.to_hash[:get_flight_id_results][:get_flight_id_result]
    rescue
      return nil
    end
  end
  
end