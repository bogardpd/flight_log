# Provides utilities for generating GeoJSON output from flight data.
module GeoJSON
  
  TEMP_FILE = "tmp/flights.geojson"
  COORD_DIGITS = 3 # Number of digits to round coordinates to
  DEG_INTERVAL = 1.0 # Degrees per step for great circle route points

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
    flights = flights.includes(:origin_airport, :destination_airport)
    
    airport_visits = Airport.visit_table_data(flights).to_h{|a| [a[:id], a[:visit_count]]}
    airport_data = Airport.where(id: airport_visits.keys)
      .pluck(:id, :iata_code, :latitude, :longitude)
      .to_h{|a| [a[0], {
        iata_code: a[1],
        latitude: a[2],
        longitude: a[3]}]}
    airport_features = airport_data.map{|id, airport| {
      type: "Feature",
      geometry: {
        type: "Point",
        coordinates: [
          airport[:longitude].round(COORD_DIGITS),
          airport[:latitude].round(COORD_DIGITS)]
      },
      properties: {
        iata: airport[:iata_code],
        freq: airport_visits[id],
      }
    }}
    
    route_data = Hash.new()
    flights.each do |flight|
      route_id = [flight.origin_airport_id, flight.destination_airport_id].sort
      for_rev = flight.origin_airport_id < flight.destination_airport_id ? [1,0] : [0,1]
      freqs = {freq: 1, freq_forward: for_rev[0], freq_reverse: for_rev[1]}
      if route_data.key?(route_id)
        # Route exists in hash. Add frequencies.
        freqs.each{|k,v| route_data[route_id][k] += v}
      else
        # Add route to hash.
        route_data[route_id] = {
          orig_iata: flight.origin_airport.iata_code,
          orig_coord: Coordinate.new(*flight.origin_airport.coordinates),
          dest_iata: flight.destination_airport.iata_code,
          dest_coord: Coordinate.new(*flight.destination_airport.coordinates),
          **freqs
        }
      end
    end
    route_features = route_data.map{|id, f| {
      type: "Feature",
      geometry: {
        type: "MultiLineString",
        coordinates: GreatCircle
          .gc_route_coords(f[:orig_coord], f[:dest_coord], DEG_INTERVAL)
          .map{|line_string| line_string
            .map{|point| [
              point.lon.round(COORD_DIGITS),
              point.lat.round(COORD_DIGITS),
            ]}
          }
      },
      properties: {
        orig_iata: f[:orig_iata],
        dest_iata: f[:dest_iata],
        freq: f[:freq],
        freq_forward: f[:freq_forward],
        freq_reverse: f[:freq_reverse],
      }
    }}    
    
    output = {
      type: "FeatureCollection",
      features: [*airport_features, *route_features]
    }

    gj_output = output.to_json
    write_temp_file(gj_output)
    return gj_output

  end

  private

  # Writes JSON to a temporary file.
  # 
  # @param json [Object] JSON to write to file
  # @return [nil]
  def self.write_temp_file(json)
    f = File.open(TEMP_FILE, "w")
    f << json
    f.close
    return nil
  end

end