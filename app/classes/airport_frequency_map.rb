class AirportFrequencyMap < Map
  
  # Initialize a map of a collection of airports (showing no routes between
  # them), surrounded by rings with area proportional to the number of visits
  # to each airport.
  # Params:
  # +flights+:: A collection of Flights.
  # +region+:: The ICAO regions to show. World map will be shown if region is left blank.
  def initialize(flights, region: [""])
    @airport_frequencies = Airport.frequency_hash(flights)
    @airports_in_region = Airport.in_region_hash(region).select{|k,v| @airport_frequencies.keys.include?(k)}
    @airports_all = Airport.in_region_hash([]).select{|k,v| @airport_frequencies.keys.include?(k)}
  end

  def test_output
    return airport_frequencies
  end
  
  private

  # Returns an array of airport IDs
  def airports_normal
    return @airports_in_region.keys
  end

  # Returns an array of airport IDs
  def airports_out_of_region
    return @airports_all.keys - @airports_in_region.keys
  end

  # Returns a hash of airport frequencies in the form of {airport_id => frequency}
  def airport_frequencies
    return @airport_frequencies
  end

  # Returns a string of Great Circle Mapper airport options.
  def gcmap_airport_options
    return "b:disc5:red"
  end
  
  def map_description
    return "Map of airport locations and number of visits"
  end
  
end