class Map
  include ActionView::Helpers
  include ActionView::Context

  ICAO_REGIONS = {
    "World":            %w(),
    "North America":    %w(C K M T),
    "Europe":           %w(B E L),
    "Pacific/Oceania":  %w(A N PH R Y)
  }
  
  # Returns a SafeBuffer containing HTML for a Great Circle Mapper map.
  def gcmap
    return content_tag(:div, class: "center") do
      concat link_to(image_tag(Rails.application.routes.url_helpers.gcmap_image_path(gcmap_airport_options, gcmap_query.gsub("/","_"), Map.hash_image_query(gcmap_query)), :alt => map_description, :class => "map"), "http://www.gcmap.com/mapui?PM=#{gcmap_airport_options}&MP=r&MS=wls2&P=#{gcmap_query}", target: "_blank")
      concat content_tag(:div, ActiveSupport::SafeBuffer.new + "Map generated by " + link_to("Great Circle Mapper", "http://www.gcmap.com/", target: "_blank"), class: %w(credit map-credit))
    end
  end

  # Returns a hash of region details for this particular map, used by ApplicationHelper.gcmap_region_select_links.
  def gcmap_regions(selected_region)
    @airport_details ||= airport_details
    used_airports = @airport_details.keys
    region_hash = Hash.new

    ICAO_REGIONS.each do |name, icao|
      if selected_region.uniq.sort == icao.uniq.sort
        region_hash[name] = {selected: true}
      else
        in_region = Airport.in_region_ids(icao).sort
        if ((in_region & used_airports).any? && (used_airports - in_region).any?) || icao == []
          # This region has airports, but is not identical to world OR this region is world.
          region_hash[name] = {selected: false, icao: icao}
        end
      end
    end

    return region_hash
  end

  # Returns a SafeBuffer contining XML data for a GPX file.
  def gpx

  end

  # Returns a SafeBuffer containing XML data for a KML file.
  def kml
    
  end

  def exists?
    gcmap_query.present?
  end
  
  # Return a hash of a map query based on a secret key
  # Params: 
  # +query+:: The query to hash
  def self.hash_image_query(query)
    Digest::MD5.hexdigest(query + ENV["IMAGE_KEY"])
  end
  
  private

  # Returns a hash of airport details in the form of {airport_id => {latitude: 0, longitude: 0, city: "City", country: "Country", iata: "AAA", icao: "AAAA"}}.
  def airport_details
    details = Hash.new

    airport_ids = Array.new
    airport_ids |= airports_normal
    airport_ids |= airports_highlighted
    airport_ids |= airports_out_of_region
    airport_ids |= routes_normal.flatten
    airport_ids |= routes_highlighted.flatten
    airport_ids |= routes_unhighlighted.flatten
    airport_ids |= routes_out_of_region.flatten
    airport_ids = airport_ids.uniq.sort

    airports = Airport.where(id: airport_ids)
    airports.each do |airport|
      details[airport.id] = {iata: airport.iata_code, icao: airport.icao_code, latitude: airport.latitude, longitude: airport.longitude, city: airport.city, country: airport.country, visits: airport_frequencies[airport.id]}
    end

    return details
  end

  # Returns an array of airport IDs
  def airports_normal
    return Array.new
  end

  # Returns an array of airport IDs
  def airports_highlighted
    return Array.new
  end

  # Returns an array of airport IDs
  def airports_out_of_region
    return Array.new
  end

  # Returns a hash of airport frequencies in the form of {airport_id => frequency}
  def airport_frequencies
    return Hash.new
  end

  # Returns an array of routes in the form of [[airport_1_id, airport_2_id]]. The IDs should be sorted within each pair.
  def routes_normal
    return Array.new
  end

  # Returns an array of routes in the form of [[airport_1_id, airport_2_id]]. The IDs should be sorted within each pair.
  def routes_highlighted
    return Array.new
  end

  # Returns an array of routes in the form of [[airport_1_id, airport_2_id]]. The IDs should be sorted within each pair.
  def routes_unhighlighted
    return Array.new
  end

  # Returns an array of routes in the form of [[airport_1_id, airport_2_id]]. The IDs should be sorted within each pair.
  def routes_out_of_region
    return Array.new
  end

  # Returns a hash of route frequencies in the form of {[airport_1_id, airport_2_id] => frequency}
  def route_frequencies
    return Hash.new
  end

  def map_description
    return "Map of flight routes"
  end

  # GREAT CIRCLE MAPPER METHODS

  # Returns a string of Great Circle Mapper airport options.
  def gcmap_airport_options
    return "b:disc5:black"
  end

  # Returns true if highlighted airports should display names, fals otherwise
  def gcmap_include_highlighted_airport_names?
    return false
  end

  def gcmap_query
    @airport_details ||= airport_details
    query_sections = Array.new
    
    if routes_out_of_region.any? || routes_unhighlighted.any?
      
      query_sections.push("c:%23FF7777")
      
      # Add routes outside region:
      if routes_out_of_region.any?
        query_sections.push(gcmap_route_string(routes_out_of_region, noext: true))
      end
    
      # Add unhighlighted routes:
      if routes_unhighlighted.any?
        query_sections.push(gcmap_route_string(routes_unhighlighted))
      end
      
    end
    
    if routes_normal.any? || routes_highlighted.any?
      
      query_sections.push("c:red")
      
      # Add routes inside region:
      if routes_normal.any?
        query_sections.push(gcmap_route_string(routes_normal))
      end
    
      # Add highlighted routes:
      if routes_highlighted.any?
        query_sections.push("w:2")
        query_sections.push(gcmap_route_string(routes_highlighted))
      end
    
    end
    
    # Add airports:
    if airports_normal.any?
      query_sections.push(gcmap_airport_string(airports_normal))
    end
    
    # Add highlighted airports:
    if airports_highlighted.any?
      if gcmap_include_highlighted_airport_names?
        query_sections.push(%Q(m:p:ring11:black%2B"%25N"12r%3A%23666))
      else
        query_sections.push("m:p:ring11:black")
      end
      query_sections.push(gcmap_airport_string(airports_highlighted))
    end
    
    # Add frequency rings:
    if airport_frequencies.any?
      query_sections.push(gcmap_airport_frequency_rings_string(airport_frequencies))
    end
    
    if query_sections.length > 0
      return query_sections.join(",")
    else
      return " "
    end
  end

  # Accepts an array of airport ID pairs and returns a string of IATA codes.
  def gcmap_airport_string(airports)
    return airports.map{|a| @airport_details[a][:iata]}.join(",")
  end

  # Return an array of IATA codes preceeded by appropriate Great Circle
  # Mapper-formatted airport disc sizes.
  def gcmap_airport_frequency_rings_string(frequencies)
    
    max_gcmap_ring = 99 # Define the maximum ring size gcmap will allow
    previous_airport_value = nil
    frequency_max = 1.0
    frequency_scaled = 0
    
    query = Array.new      
    region_frequencies = Array.new
    
    airports_normal.each do |airport|
      region_frequencies.push(iata_code: @airport_details[airport][:iata], frequency: frequencies[airport])
    end
    region_frequencies.sort_by! { |airport| [-airport[:frequency], airport[:iata_code]] }
    
    region_frequencies.each do |airport|
      if airport == region_frequencies.first
        # This is the first circle, so define its color:
        query.push("m:p:ring#{max_gcmap_ring}:black")
        query.push(airport[:iata_code])
        frequency_max = airport[:frequency].to_f
      elsif airport[:frequency] == previous_airport_value
        # Value is the same as previous, so no need to define ring size:
        query.push(airport[:iata_code])
      else
        frequency_scaled = Math.sqrt((airport[:frequency].to_f / frequency_max)*(max_gcmap_ring**2)).ceil.to_i # Scale frequency range from 1..max_gcmap_ring
        query.push("m:p:ring#{frequency_scaled}")
        query.push(airport[:iata_code])
      end
      previous_airport_value = airport[:frequency]
    end
    
    return query.join(",")
  end

  # Accepts an array of airport id pairs (from one of the routes_ methods) and returns a string of IATA code pairs.
  def gcmap_route_string(routes, noext: false)
    # Generate an array of airport IDs, sorted by most used to least used:
    frequency_order = routes.flatten.each_with_object(Hash.new(0)){|key, hash| hash[key] += 1}.sort_by{|k,v| -v}.map{|x| x[0]}
    
    route_groups = Array.new
    # Loop through ordered airport IDs and generate gcmap querystring for it
    frequency_order.each do |airport_id|
      break if routes.empty?
      # Save all routes with this airport id to matching, and retain only the routes that don't match:
      matching, routes = routes.partition{|x| x[0] == airport_id || x[1] == airport_id}
      if matching.any?
        # Create querystring:
        route_groups.push("o:noext") if noext
        route_groups.push(@airport_details[airport_id][:iata] + "-" + matching.map{|x| @airport_details[x[0] == airport_id ? x[1] : x[0]][:iata]}.sort.join("/")) # The map with ternary statement is used to ensure we keep routes where both airports are the same; otherwise we could just use flatten and reject.
      end
    end
    return route_groups.join(",")
  end

  

  # Old methods:

  # def airport_options
  #   return "b:disc5:black"
  # end
  
  # def alt_tag
  #   return "Map of flight routes"
  # end
    
  # def routes_inside_region
  #   return Array.new
  # end

  # def routes_outside_region
  #   return Array.new
  # end

  # def routes_highlighted
  #   return Array.new
  # end
  
  # def routes_unhighlighted
  #   return Array.new
  # end

  # def airports_inside_region
  #   return Array.new
  # end
  
  # def airports_outside_region
  #   return Array.new
  # end

  # def airports_highlighted
  #   return Array.new
  # end
  
  # def airports_frequency
  #   return Array.new
  # end

  
  
  # Convert a set of pairs into a Great Circle Mapper formatted querystring, minimizing string length.
  # Params:
  # +pairs+:: An array of arrays of two IATA codes.
  # def compressed_routes(pairs)
  #   routes = Array.new
  #   pairs = pairs.uniq.sort_by{|k| [k[0],k[1]]}
  #   previous_origin = nil
  #   route_string = nil
  #   pairs.each do |pair|
  #     if pair[0] == previous_origin && route_string
  #       route_string += "/#{pair[1]}"
  #     else
  #       routes.push(route_string) if route_string
  #       route_string = "#{pair[0]}-#{pair[1]}"
  #     end
  #     routes.push(route_string) if (pair == pairs.last && route_string)
  #     previous_origin = pair[0]
  #   end
  #   return routes
  # end
  
end