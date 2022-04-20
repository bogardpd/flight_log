# Provides utilities for interacting with with FlightAware's AeroAPI (version
# 4).
#
# This is used to look up {Flight} data that couldn't be found from a
# {BoardingPass} or {PKPass} for the purposes of prepopulating the
# {FlightsController#new new flight} form. It's also used to look up {Airport}
# data when creating a {AirportsController#new new airport}.
#
# Note: Since AeroAPI has its own database of flights, airports, and routes,
# when you see these terms in this documentation, it refers to AeroAPI and
# not this applications models, unless it specifically links to {Flight},
# {Airport}, or {Route}.
#
# @see https://flightaware.com/aeroapi/portal/documentation

module AeroAPI4

  API_SERVER = "https://aeroapi.flightaware.com/aeroapi"

  # The default error message to return if an AeroAPI lookup failed.
  ERROR = "We couldn’t find your flight data on FlightAware. You will have to manually enter some fields."

  # Passes paths to AeroAPI and gets a hash of results.
  #
  # @param path [String] an AeroAPI path, not including the server.
  # @return [Dict] the AeroAPI response
  def self.api_request(path)
    uri = URI.parse("#{API_SERVER}#{path}")
    headers = {
      'x-apikey': Rails.application.credentials[:aeroapi][:v4][:api_key]
    }
    res = Net::HTTP.get_response(uri, headers)
    return JSON.parse(res.body).with_indifferent_access
  end

  # Looks up the latitude and longitude for an ICAO airport code.
  #
  # @param airport_icao [String] an ICAO airport code
  # @return [Array<Float>] latitude and longitude in decimal degrees
  def self.airport_coordinates(airport_icao)
    begin
      res = api_request("/airports/#{airport_icao}")
      return nil unless (res[:latitude] && res[:longitude])
      return [res[:latitude].to_f, res[:longitude].to_f]
    rescue
      return nil
    end
  end

  # Looks up airport info for an ICAO airport code.
  #
  # @param airport_icao [String] an ICAO airport code
  # @return [Hash] a hash of airport details
  def self.airport_lookup(airport_icao)
    begin
      res = api_request("/airports/#{airport_icao}")
      return nil unless res[:timezone]
      output = {
        timezone: res[:timezone],
        display_code: (res[:alternate_ident] || airport_icao),
        city: res[:city],
        name: res[:name],
      }
      return output
    rescue
      return nil
    end
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
      res = api_request("/flights/#{ident}")
      return nil unless res[:flights]
      return res[:flights]
    rescue
      return nil
    end
  end

  # Looks up flight data for an AeroAPI fa_flight_id.
  # 
  # @param fa_flight_id [String] a FlightAware/AeroAPI unique flight ID
  # @return [Hash] flight data
  def self.form_values(fa_flight_id)
    return nil unless fa_flight_id
    fields = Hash.new
    
    begin
      res = api_request("/flights/#{fa_flight_id}")
      return nil unless res[:flights] and res[:flights].first
      flight = res[:flights].first
    rescue
      return nil
    end
    
    fields.store(:origin_airport_icao, flight.dig(:origin, :code)) if flight.dig(:origin, :code)
    fields.store(:destination_airport_icao, flight.dig(:destination, :code)) if flight.dig(:destination, :code)
    fields.store(:aircraft_family_icao, flight[:aircraft_type]) if flight[:aircraft_type]
    
    fields.store(:operator_icao, flight[:operator]) if flight[:operator]
    
    begin
      fields.store(:departure_utc, Time.parse(flight[:scheduled_out]).utc) if flight[:scheduled_out]
    end
    fields.store(:tail_number, flight[:registration]) if flight[:registration]
    
    return fields
  end

  # Looks up an AeroAPI unique flight ID for flights matching a flight
  # identifier string and UTC departure datetime.
  #
  # A flight identifier is a string containing an airline code and a flight
  # number, with no space between them (e.g. AA1234 or UAL5678). The airline
  # can be ICAO or IATA, but IATA codes that contain numbers (e.g. B6) may not
  # be used (the ICAO code must then be used in these cases).
  #
  # @param ident [String] a flight identifier
  # @param scheduled_out_utc [DateTime] a UTC departure time
  # @return [String] an AeroAPI fa_flight_id
  def self.get_flight_id(ident, scheduled_out_utc)
    begin
      res = api_request("/flights/#{ident}")
      return nil unless res[:flights]
    rescue
      return nil
    end

    flight = res[:flights].find {|f|
      begin
        Time.parse(f[:scheduled_out]) == scheduled_out_utc
      rescue
        false
      end
    }
    return flight.nil? ? nil : flight[:fa_flight_id]

  end

  # Returns the best departure time from provided flight data.
  #
  # @param flight_hash [Hash] an item from a flight_lookup array
  # @return [Time] a UTC timestamp
  def self.departure_time(flight_hash)
    times = [
      flight_hash[:scheduled_out],
      flight_hash[:scheduled_off],
      flight_hash[:estimated_out],
      flight_hash[:estimated_off],
      flight_hash[:actual_out],
      flight_hash[:actual_off],
    ].compact
    return nil unless times.any?
    begin
      return Time.parse(times.first).utc
    rescue
      return nil
    end
  end

  # Returns the best arrival time from provided flight data.
  #
  # @param flight_hash [Hash] an item from a flight_lookup array
  # @return [Time] a UTC timestamp
  def self.arrival_time(flight_hash)
    times = [
      flight_hash[:scheduled_in],
      flight_hash[:scheduled_on],
      flight_hash[:estimated_in],
      flight_hash[:estimated_on],
      flight_hash[:actual_in],
      flight_hash[:actual_on],
    ].compact
    return nil unless times.any?
    begin
      return Time.parse(times.first).utc
    rescue
      return nil
    end
  end

end