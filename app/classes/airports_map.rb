class AirportsMap < Map
  
  # Initialize a map of a collection of airports (showing no routes between them)
  # Params:
  # +airports+:: A collection of Airport objects.
  # +region+:: The ICAO regions to show. World map will be shown if region is left blank.
  def initialize(airports, region: [""])
    @airport_normal_ids = airports.in_region_ids(region)
    @airport_out_of_region_ids = airports.pluck(:id) - @airport_normal_ids
  end
  
  private

  # Returns an array of airport IDs
  def airports_normal
    return @airport_normal_ids
  end

  # Returns an array of airport IDs
  def airports_out_of_region
    return @airport_out_of_region_ids
  end
  
  def map_description
    return "Map of airport locations"
  end
  
end