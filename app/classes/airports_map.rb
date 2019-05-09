# Defines a map of a collection of {Airport}s (showing no {Flight}s between them).

class AirportsMap < Map
  
  # Initialize a map of a collection of {Airport}s (showing no {Flight}s between them).
  # 
  # @param airports [Array<Airport>] a collection of {Airport}s
  # @param region [Array<String>] the ICAO prefixes to show (e.g. ["K","PH"]).
  #   World map will be shown if region is left blank.
  # @see Map#gcmap_regions
  def initialize(airports, region: [""])
    @airport_normal_ids = airports.in_region_ids(region)
    @airport_out_of_region_ids = airports.pluck(:id) - @airport_normal_ids
  end
  
  private

  # Returns an array of airport IDs for airports with no special formatting.
  #
  # @return [Array<Number>] airport IDs
  def airports_normal
    return @airport_normal_ids
  end

  # Returns an array of airport IDs for airports that are not in the current
  # region.
  #
  # @return [Array<Number>] airport IDs
  def airports_out_of_region
    return @airport_out_of_region_ids
  end
  
  # Returns the map description.
  #
  # @return [String] the map description
  def map_description
    return "Map of airport locations, created by Paul Bogard’s Flight Historian"
  end
  
end