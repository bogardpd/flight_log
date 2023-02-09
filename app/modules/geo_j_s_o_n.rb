# Provides utilities for generating GeoJSON output from flight data.
module GeoJSON
  
  TEMP_FILE = "tmp/flights.geojson"

  # Generate GeoJSON output from a collection of {Flight flights}.
  #
  # This method also saves the output to the file location specified in
  # TEMP_FILE. It will be overwritten each time the method is run.
  #
  # @param flights [Array<Flight>] a collection of {Flight Flights}
  # @return [String] GeoJSON data.
  # 
  # @see https://geojson.org/
  def self.flights_to_geojson(flights)
    flights = flights.includes(:origin_airport, :destination_airport, :airline)

    airport_points = Airport.visit_table_data(flights).map{|a| {id: a[:id], iata: a[:iata_code], visits: a[:visit_count]}}
    flight_line_strings = Hash.new()
    flights.each do |flight|
      route_id = [flight.origin_airport_id, flight.destination_airport_id].sort
      for_rev = flight.origin_airport_id < flight.destination_airport_id ? [1,0] : [0,1]
      freqs = {freq: 1, freq_forward: for_rev[0], freq_reverse: for_rev[1]}
      if flight_line_strings.key?(route_id)
        # Route exists in hash. Add frequencies.
        freqs.each{|k,v| flight_line_strings[route_id][k] += v}
      else
        # Add route to hash.
        flight_line_strings[route_id] = {
          orig_iata: flight.origin_airport.iata_code,
          orig_coord: Coordinate.new(*flight.origin_airport.coordinates),
          dest_iata: flight.destination_airport.iata_code,
          dest_coord: Coordinate.new(*flight.destination_airport.coordinates),
          **freqs
        }
      end
    end
    
    # TODO: convert airport_points and flight_line_strings to GeoJSON.
    pp flight_line_strings

    # write_temp_file(output)

  end

end