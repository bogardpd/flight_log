class AirportFrequencyMap < Map
  
  # Initialize a map of a collection of airports (showing no routes between
  # them), surrounded by rings with area proportional to the number of visits
  # to each airport.
  # Params:
  # +flights+:: A collection of Flights.
  # +region+:: The region to show. World map will be shown if region is left blank.
  def initialize(flights, region: :world)
        
    airport_frequencies = Airport.frequency_hash(flights)
    @airport_codes = Airport.region_iata_codes(flights, region)
    
    @airport_array = Array.new
    @airport_codes.each do |airport, code|
      @airport_array.push(iata_code: code, frequency: airport_frequencies[airport])
    end
    @airport_array = @airport_array.sort_by { |airport| [-airport[:frequency], airport[:iata_code]] }
    
    
  end
  
  private
  
    def airport_options
      return "b:disc5:red"
    end
  
    def airports_inside_region
      return @airport_codes.values
    end
    
    # Return an array of IATA codes preceeded by appropriate Great Circle
    # Mapper-formatted airport disc sizes.
    def airports_frequency
      
      max_gcmap_ring = 99 # Define the maximum ring size gcmap will allow
      previous_airport_value = nil
      frequency_max = 1.0
      frequency_scaled = 0
      
      query = Array.new
      
      @airport_array.each do |airport|
        if airport == @airport_array.first
          # This is the first circle, so define its color:
          query.push("m:p:ring#{max_gcmap_ring}:black")
          query.push(airport[:iata_code])
          frequency_max = airport[:frequency].to_f
        elsif airport[:frequency] == previous_airport_value
          # Value is the same as previous, so no need to define circle size:
          query.push(airport[:iata_code])
        else
          frequency_scaled = Math.sqrt((airport[:frequency].to_f / frequency_max)*(max_gcmap_ring**2)).ceil.to_i # Scale frequency range from 1..max_gcmap_ring
          query.push("m:p:ring#{frequency_scaled}")
          query.push(airport[:iata_code])
        end
        previous_airport_value = airport[:frequency]
      end
      
      return query
    end
    
    # Analyze a flight collection, and return a hash of IATA codes and the
    # number of visits to each.
    # Params:
    # +flight_array+:: A collection of Flights (sorted by UTC departure).
    def frequency_hash
      airport_frequency = Hash.new(0) # All airports start with 0 flights
      previous_trip_id = nil;
      previous_trip_section = nil;
      previous_destination_airport_iata_code = nil;
      @flights.each do |flight|
        unless (flight.trip_id == previous_trip_id && flight.trip_section == previous_trip_section && flight.origin_iata_code == previous_destination_airport_iata_code)
          # This is not a layover, so count this origin airport
          airport_frequency[flight.origin_airport_id] += 1
        end
        airport_frequency[flight.destination_airport_id] += 1
        previous_trip_id = flight.trip_id
        previous_trip_section = flight.trip_section
        previous_destination_airport_iata_code = flight.destination_iata_code
      end
      return airport_frequency
    end
  
end