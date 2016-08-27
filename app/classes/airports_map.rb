class AirportsMap < Map
  
  # Initialize a map of a collection of airports (showing no routes between them)
  # Params:
  # +airports+:: A collection of Airport objects.
  # +region+:: The region to show. World map will be shown if region is left blank.
  def initialize(airports, region: :world)
    @region = region
    @airports = airports
    airport_ids = Array.new
    airports.each do |airport|
      airport_ids.push(airport[:id])
    end
    if region == :conus
      @airport_codes = Airport.where(id: airport_ids).where(region_conus: true).order(:iata_code).pluck(:iata_code)
    else
      @airport_codes = Airport.where(id: airport_ids).order(:iata_code).pluck(:iata_code)
    end
  end
  
  private
  
    def airports_inside_region
      return @airport_codes
    end
  
    
  
end