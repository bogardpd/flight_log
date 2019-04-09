class AirportsMap < Map
  
  # Initialize a map of a collection of airports (showing no routes between them)
  # Params:
  # +airports+:: A collection of Airport objects.
  # +region+:: The region to show. World map will be shown if region is left blank.
  def initialize(airports, region: [""])
    @airport_codes = airports.in_region_iata_codes(region)
    @outside = airports.pluck(:iata_code) - @airport_codes
  end
  
  private
  
    def airports_inside_region
      return @airport_codes
    end
    
    def airports_outside_region
      return @outside
    end
    
    def alt_tag
      return "Map of airport locations"
    end
  
    
  
end