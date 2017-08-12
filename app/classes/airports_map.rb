class AirportsMap < Map
  
  # Initialize a map of a collection of airports (showing no routes between them)
  # Params:
  # +airports+:: A collection of Airport objects.
  # +region+:: The region to show. World map will be shown if region is left blank.
  def initialize(airports, region: [""])
    region = region.to_s.split(",")
    @airport_codes = airports.in_region(region)
  end
  
  private
  
    def airports_inside_region
      return @airport_codes
    end
    
    def alt_tag
      return "Map of airport locations"
    end
  
    
  
end