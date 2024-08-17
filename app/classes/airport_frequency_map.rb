# Defines a map of a collection of {Airport Airports} (showing no {Flight Flights} between
# them), surrounded by rings with area proportional to the number of visits
# to each airport.

class AirportFrequencyMap < Map
  
  # Initialize a map of a collection of {Airport Airports} (showing no {Flight Flights} between
  # them), surrounded by rings with area proportional to the number of visits
  # to each airport.
  # 
  # @param flights [Array<Flight>] a collection of {Flight Flights}
  def initialize(id, flights)
    @id = id
    @flights = flights
    @airport_frequencies = Airport.visit_frequencies(flights)
    @airports_all = Airport.pluck(:id).select{|v| @airport_frequencies.keys.include?(v)}
  end

  # Creates JSON for a {https://geojson.org/ GeoJSON} map.
  #
  # @return [String] JSON for a {https://geojson.org/ GeoJSON} map.
  def geojson
    return GeoJSON.flights_to_geojson(@flights, include_routes: false)
  end

  # Creates XML for a {http://graphml.graphdrawing.org/ GraphML} graph.
  #
  # @return [ActiveSupport::Safebuffer] XML for a
  #   {http://graphml.graphdrawing.org/ GraphML} graph.
  def graphml
    return nil unless @airports_all
    return nil unless @flights
    return GraphML.graph_airports(@airports_all, @flights)
  end
  
  private

  # Returns an array of airport IDs for airports with no special formatting.
  #
  # @return [Array<Number>] airport IDs
  def airports_normal
    return @airports_all
  end

  # Create a hash for looking up the number of times an airport has been
  # visited by airport ID.
  #
  # @return [Hash{Number => Number}] a hash of airport frequencies in the form
  #   of {airport_id => frequency}
  def airport_frequencies
    return @airport_frequencies
  end

  # Returns Great Circle Mapper airport options.
  #
  # @return [String] Great Circle Mapper airport options
  def gcmap_airport_options
    return "b:disc5:red"
  end
  
  # Returns the map description.
  #
  # @return [String] the map description
  def map_description
    return "Map of airport locations and number of visits, created by Paul Bogard’s Flight Historian"
  end

  # Returns a string to use in the class for the map.
  #
  # @return [String] the map type
  def map_type
    return "airport-frequency-map"
  end
  
end