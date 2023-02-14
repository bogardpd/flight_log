# Defines a map of a single {Flight}.

class SingleFlightMap < Map
  
  # Initialize a map of a single {Flight}.
  # 
  # @param id [Symbol] an ID for the map
  # @param flight [Flight] the {Flight} to map
  def initialize(id, flight)
    @id = id
    @codes = [flight.origin_airport.iata_code, flight.destination_airport.iata_code]
    @flight = flight
  end

  # Creates JSON for a {https://geojson.org/ GeoJSON} map.
  #
  # @return [String] JSON for a {https://geojson.org/ GeoJSON} map.
  def geojson
    flights = Flight.where(id: @flight.id)
    return GeoJSON.flights_to_geojson(flights, include_frequencies: false)
  end
  
  private

  # Returns Great Circle Mapper airport options.
  #
  # @return [String] Great Circle Mapper airport options
  def gcmap_airport_options
    return "*"
  end

  # Returns the map description.
  #
  # @return [String] the map description
  def map_description
    "Map of flight route between #{@codes[0]} and #{@codes[1]}, created by Paul Bogard’s Flight Historian"
  end

  # Returns a string to use in the class for the map.
  #
  # @return [String] the map type
  def map_type
    return "single-flight-map"
  end


  # Creates an array of numerically-sorted pairs of airport IDs for routes with
  # no special formatting.
  # 
  # @return [Array<Array>] an array of routes in the form of [[airport_1_id,
  #   airport_2_id]].
  def routes_normal
    return [[@flight.origin_airport_id, @flight.destination_airport_id].sort]
  end
  
end