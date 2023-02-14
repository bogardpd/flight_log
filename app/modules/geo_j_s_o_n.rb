# Provides utilities for generating GeoJSON output from flight data.
module GeoJSON
  
  TEMP_FILE = "tmp/flights.geojson"
  COORD_DIGITS = 3 # Number of digits to round coordinates to
  DEG_INTERVAL = 1.0 # Degrees per step for great circle route points

  # Generate GeoJSON output from a collection of {Airport airports}.
  #
  # This method also saves the output to the file location specified in
  # TEMP_FILE. It will be overwritten each time the method is run.
  #
  # @param airports [Array<Airport>] a collection of {Airport Airports}
  # @return [String] GeoJSON data.
  # 
  # @see https://geojson.org/
  def self.airports_to_geojson(airports)
    airports = airports.where.not(({latitude: nil, longitude: nil}))
    airport_data = airports.pluck(:id, :iata_code, :latitude, :longitude)
      .to_h{|a| [a[0], {
        iata_code: a[1],
        latitude: a[2],
        longitude: a[3],
        freq: nil,
      }]}
    airport_features = airport_data.map{|id, airport|
      airport_feature(airport, false)
    }
    output = {
      type: "FeatureCollection",
      features: airport_features
    }
    gj_output = output.to_json
    write_temp_file(gj_output)
    return gj_output
  end
  
  # Generate GeoJSON output from a collection of {Flight flights}.
  #
  # This method also saves the output to the file location specified in
  # TEMP_FILE. It will be overwritten each time the method is run.
  #
  # @param flights [Array<Flight>] a collection of {Flight Flights}
  # @param include_frequencies [Boolean] if false, will not include frequencies
  #   for airports and routes
  # @param include_routes [Boolean] if false, will only return airport points
  #   (no flight linestrings)
  # @return [String] GeoJSON data.
  # 
  # @see https://geojson.org/
  def self.flights_to_geojson(flights, include_frequencies: true, include_routes: true)
    flights = flights.includes(:origin_airport, :destination_airport)
    
    airport_visits = Airport.visit_table_data(flights).to_h{|a| [a[:id], a[:visit_count]]}
    airports = Airport.where(id: airport_visits.keys).where.not({latitude: nil, longitude: nil})
    airport_data = airports.pluck(:id, :iata_code, :latitude, :longitude)
      .to_h{|a| [a[0], {
        iata_code: a[1],
        latitude: a[2],
        longitude: a[3],
        freq: airport_visits[a[0]],
      }]}
    airport_features = airport_data.map{|id, airport|
      airport_feature(airport, include_frequencies)
    }
    
    if include_routes
      route_data = Hash.new()
      flights.each do |flight|
        route_id = [flight.origin_airport_id, flight.destination_airport_id].sort
        for_rev = flight.origin_airport_id < flight.destination_airport_id ? [1,0] : [0,1]
        freqs = {freq: 1, freq_forward: for_rev[0], freq_reverse: for_rev[1]}
        if route_data.key?(route_id)
          # Route exists in hash. Add frequencies.
          freqs.each{|k,v| route_data[route_id][k] += v}
        elsif flight.origin_airport.coordinates && flight.destination_airport.coordinates
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
      route_features = route_data.map{|id, route|
        route_feature(route, include_frequencies)
      }
    else
      route_features = []
    end 
    
    output = {
      type: "FeatureCollection",
      features: [*airport_features, *route_features]
    }

    gj_output = output.to_json
    write_temp_file(gj_output)
    return gj_output

  end

  private

  # Creates a Ruby hash in the style of a GeoJSON Point feature.
  #
  # @param airport [Hash] a hash containing iata_code, latitude, and longitude
  #   keys. May also contain an optional freq key with an airport visit count
  #   value.
  # @param include_frequencies [Boolean] if false, will not include frequencies
  #   in the returned feature.
  # 
  # @return [Hash<Hash>] Ruby hash in the style of a GeoJSON Point feature.
  def self.airport_feature(airport, include_frequencies)
    feature = {
      type: "Feature",
      geometry: {
        type: "Point",
        coordinates: [
          airport[:longitude].round(COORD_DIGITS),
          airport[:latitude].round(COORD_DIGITS)]
      },
      properties: {
        'AirportIATA': airport[:iata_code],
      }
    }
    if include_frequencies
      feature[:properties][:AirportVisitCount] = airport[:freq]
    end
    return feature
  end

  # Creates a Ruby hash in the style of a GeoJSON MultiLineString feature.
  #
  # @param route [Hash] a hash containing orig_iata, orig_coord, dest_iata, and
  #   dest_coord keys. May also contain optional freq (total flight count for
  #   this route), freq_forward (flight count from orig to dest) and
  #   freq_reverse (flight count from dest to orig) keys.
  # @param include_frequencies [Boolean] if false, will not include frequencies
  #   in the returned feature.
  # 
  # @return [Hash<Hash>] Ruby hash in the style of a GeoJSON MultiLineString
  #   feature.
  def self.route_feature(route, include_frequencies=true)
    feature = {
      type: "Feature",
      geometry: {
        type: "MultiLineString",
        coordinates: GreatCircle
          .gc_route_coords(route[:orig_coord], route[:dest_coord], DEG_INTERVAL)
          .map{|line_string| line_string
            .map{|point| [
              point.lon.round(COORD_DIGITS),
              point.lat.round(COORD_DIGITS),
            ]}
          }
      },
      properties: {
        RouteOrigIATA: route[:orig_iata],
        RouteDestIATA: route[:dest_iata],
      }
    }
    if include_frequencies
      feature[:properties].merge!({
        RouteFlightCountTotal: route[:freq],
        RouteFlightCountForward: route[:freq_forward],
        RouteFlightCountReverse: route[:freq_reverse],
      })
    end
    return feature
  end

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