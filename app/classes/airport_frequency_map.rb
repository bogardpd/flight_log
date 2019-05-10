# Defines a map of a collection of {Airport Airports} (showing no {Flight Flights} between
# them), surrounded by rings with area proportional to the number of visits
# to each airport.

class AirportFrequencyMap < Map
  
  # Initialize a map of a collection of {Airport Airports} (showing no {Flight Flights} between
  # them), surrounded by rings with area proportional to the number of visits
  # to each airport.
  # 
  # @param flights [Array<Flight>] a collection of {Flight Flights}
  # @param region [Array<String>] the ICAO prefixes to show (e.g. ["K","PH"]).
  #   World map will be shown if region is left blank.
  # @see Map#gcmap_regions
  def initialize(flights, region: [""])
    @airport_frequencies = Airport.frequency_hash(flights)
    @airports_in_region = Airport.in_region_hash(region).select{|k,v| @airport_frequencies.keys.include?(k)}
    @airports_all = Airport.in_region_hash([]).select{|k,v| @airport_frequencies.keys.include?(k)}
  end
  
  private

  # Returns an array of airport IDs for airports with no special formatting.
  #
  # @return [Array<Number>] airport IDs
  def airports_normal
    return @airports_in_region.keys
  end

  # Returns an array of airport IDs for airports that are not in the current
  # region.
  #
  # @return [Array<Number>] airport IDs
  def airports_out_of_region
    return @airports_all.keys - @airports_in_region.keys
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
  
end