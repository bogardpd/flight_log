# Defines a map of various combinations of {Flight Flights} and {Airport
# Airports}, with the ability to generate {http://www.gcmap.com/ Great Circle
# Mapper}, {https://www.topografix.com/gpx.asp GPX}, and
# {https://developers.google.com/kml/ KML} maps.
#
# While Map can be used for class methods, instances of Map are not intended
# to be used directly (which is why it specifies no constructor method).
# Instead, the subclasses which provide specific map types should be used to
# create new maps.
#
# @see http://www.gcmap.com/ Great Circle Mapper
# @see https://www.topografix.com/gpx.asp GPX: the GPS Exchange Format
# @see https://www.topografix.com/gpx.asp Keyhole Markup Language

class Map
  include ActionView::Helpers
  include ActionView::Context

  # Creates a hash of attributes for a
  # {https://docs.mapbox.com/mapbox-gl-js/guides Mapbox GL JS} map.
  # 
  # @return [Hash] Attributes for a {https://docs.mapbox.com/mapbox-gl-js/guides
  # Mapbox GL JS} map.
  # @see https://docs.mapbox.com/mapbox-gl-js/guides Mapbox GL JS
  def mapboxgl
    mapboxgl_attributes = {
      description: map_description,
      id: @id,
      map_type: map_type,
    }
    return mapboxgl_attributes
  end

  # Checks whether or not this map contains enough data to create a
  # {http://www.gcmap.com Great Circle Mapper} map.
  #
  # @return [Boolean] whether or not this map has a non-blank
  #   {http://www.gcmap.com Great Circle Mapper} querystring
  # @see http://www.gcmap.com Great Circle Mapper
  def gcmap_exists?
    gcmap_query.present?
  end

  # Returns the URL for a {http://www.gcmap.com/ Great Circle Mapper} map.
  #
  # @return [String] a URL
  # @see http://www.gcmap.com Great Circle Mapper
  def gcmap_url
    return "http://www.gcmap.com/mapui?PM=#{gcmap_airport_options}&MP=r&MS=wls2&P=#{gcmap_query}"
  end

  # Creates XML for a {https://www.topografix.com/gpx.asp GPX} map.
  #
  # @return [ActiveSupport::Safebuffer] XML for a
  #   {https://www.topografix.com/gpx.asp GPX} map.
  # @see https://www.topografix.com/gpx.asp GPX: the GPS Exchange Format
  def gpx
    @airport_details ||= airport_details
    used_airports = @airport_details.keys.sort_by{|a| @airport_details[a][:iata]}
    
    output = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
      xml.gpx(xmlns: "http://www.topografix.com/GPX/1/1", version: "1.1") do
        xml.metadata do
          xml.name(map_name)
          xml.desc(map_description)
          xml.author do
            xml.name("Paul Bogard’s Flight Historian")
            xml.link(href: "https://www.flighthistorian.com") do
              xml.text_("Paul Bogard’s Flight Historian")
            end
          end
        end

        # Create airports:
        used_airports.each do |airport|
          gpx_airport(airport, :wpt, xml)
        end

        # Create routes:
        routes = (routes_normal | routes_highlighted | routes_unhighlighted)
        if routes.any?
          routes = routes.map{|r| r.sort_by{|x| @airport_details[x][:iata]}}.uniq.sort_by{|y| [@airport_details[y[0]][:iata], @airport_details[y[1]][:iata]]}
          routes.each do |route|
            detail = route.map{|a| @airport_details[a]}
            xml.rte do
              xml.name(detail.map{|a| a[:iata]}.join("-"))
              xml.desc(detail.map{|a| a[:city]}.join(" – "))
              xml.link(href: "https://www.flighthistorian.com/routes/#{detail[0][:iata]}/#{detail[1][:iata]}")
              route.each do |airport|
                gpx_airport(airport, :rtept, xml)
              end
            end
          end
        end

      end
    end

    return output
  end

  # Creates JSON for a {https://geojson.org/ GeoJSON} map.
  #
  # @return [String] JSON for a {https://geojson.org/ GeoJSON} map.
  def geojson
    return nil unless @flights
    return GeoJSON.flights_to_geojson(@flights, highlighted_airports: @highlighted_airports, highlighted_routes: @highlighted_routes)
  end

  # Creates XML for a {http://graphml.graphdrawing.org/ GraphML} graph.
  #
  # @return [ActiveSupport::Safebuffer] XML for a
  #   {http://graphml.graphdrawing.org/ GraphML} graph.
  def graphml
    return nil unless @flights
    return GraphML.graph_flights(@flights)
  end

  # Creates XML for a {https://developers.google.com/kml/ KML} map.
  #
  # @return [ActiveSupport::Safebuffer] XML for a
  #   {https://developers.google.com/kml/ KML} map.
  # @see https://www.topografix.com/gpx.asp Keyhole Markup Language
  def kml
    @airport_details ||= airport_details
    used_airports = @airport_details.keys.sort_by{|a| @airport_details[a][:iata]}
    
    output = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
      xml.kml(xmlns: "http://www.opengis.net/kml/2.2") do
        xml.Document do
          xml.name_(map_name)
          xml.description(map_description)

          # Define styles:
          xml.Style(id: "airportMarker") do
            xml.Icon do
              xml.href("http://maps.google.com/mapfiles/kml/shapes/placemark_circle.png")
            end
          end
          xml.Style(id: "flightPath") do
            xml.LineStyle do
              xml.color("ff0000ff")
              xml.width("2")
            end
          end

          # Create airports:
          xml.Folder do
            xml.name_("Airports")
            used_airports.each do |airport|
              xml.Placemark do
                detail = @airport_details[airport]
                xml.name_([detail[:iata], detail[:icao]].join(" / "))
                xml.description(detail[:city])
                xml.StyleUrl("#airportMarker")
                xml.Point do
                  xml.coordinates("#{detail[:longitude]},#{detail[:latitude]},0")
                end
              end
            end
          end

          # Create routes:
          kml_routes(routes_normal, "Routes", xml)
          kml_routes(routes_highlighted, "Highlighted Routes", xml)
          kml_routes(routes_unhighlighted, "Unhighlighted Routes", xml)

        end
      end
    end
    return output
  end
  
  private

  # Creates a hash for looking up airport details by airport ID.
  #
  # @return [Hash{Number => Number, Number, String, String, String, String}] a
  #   hash of airport details in the form of {airport_id => {latitude: 0,
  #   longitude: 0, city: "City", country: "Country", iata: "AAA", icao:
  #   "AAAA"}}.
  def airport_details
    details = Hash.new

    airport_ids = Array.new
    airport_ids |= airports_normal
    airport_ids |= airports_highlighted
    airport_ids |= routes_normal.flatten
    airport_ids |= routes_highlighted.flatten
    airport_ids |= routes_unhighlighted.flatten
    airport_ids = airport_ids.uniq.sort

    airports = Airport.where(id: airport_ids)
    airports.each do |airport|
      details[airport.id] = {iata: airport.iata_code, icao: airport.icao_code, latitude: airport.latitude, longitude: airport.longitude, city: airport.city, country: airport.country, visits: airport_frequencies[airport.id]}
    end

    return details
  end

  # Returns an array of airport IDs for airports with no special formatting.
  #
  # @return [Array<Number>] airport IDs
  def airports_normal
    return Array.new
  end

  # Returns an array of airport IDs for airports that should be emphasized.
  #
  # @return [Array<Number>] airport IDs
  def airports_highlighted
    return Array.new
  end
  
  # Create a hash for looking up the number of times an airport has been
  # visited by airport ID.
  #
  # @return [Hash{Number => Number}] a hash of airport frequencies in the form
  #   of {airport_id => frequency}
  def airport_frequencies
    return Hash.new
  end

  # Creates an array of numerically-sorted pairs of airport IDs for routes with
  # no special formatting.
  # 
  # @return [Array<Array>] an array of routes in the form of [[airport_1_id,
  #   airport_2_id]].
  def routes_normal
    return Array.new
  end

  # Creates an array of numerically-sorted pairs of airport IDs for routes that
  # should be emphasized.
  # 
  # @return [Array<Array>] an array of routes in the form of [[airport_1_id,
  #   airport_2_id]].
  def routes_highlighted
    return Array.new
  end

  # Creates an array of numerically-sorted pairs of airport IDs for routes that
  # should be de-emphasized.
  # 
  # @return [Array<Array>] an array of routes in the form of [[airport_1_id,
  #   airport_2_id]].
  def routes_unhighlighted
    return Array.new
  end

  # Create a hash for looking up the number of times an route has been flown
  # by numerically-sorted pairs of airport ID.
  #
  # @return [Hash{Array<Number, Number> => Number}] a hash of route frequencies
  #   in the form of {[airport_1_id, airport_2_id] => frequency}.
  def route_frequencies
    return Hash.new
  end

  # Returns the map name.
  #
  # @return [String] the map name
  def map_name
    return "Flights"
  end

  # Returns the map description.
  #
  # @return [String] the map description
  def map_description
    return "Map of flight routes, created by Paul Bogard’s Flight Historian"
  end

  # Returns a string to use in the class for the map.
  #
  # @return [String] the map type
  def map_type
    return "generic-map"
  end

  # GREAT CIRCLE MAPPER METHODS

  # Returns Great Circle Mapper airport options.
  #
  # @return [String] Great Circle Mapper airport options
  def gcmap_airport_options
    return "b:disc5:black"
  end

  # Returns true if highlighted airports should display names, false otherwise.
  #
  # @return [Boolean] whether or not highlighted airports should display names
  def gcmap_include_highlighted_airport_names?
    return false
  end

  # Creates a Great Circle Mapper querystring based on the airports, routes,
  # and options associated with this Map instance.
  # 
  # @return [String] a Great Circle Mapper querystring
  def gcmap_query
    @airport_details ||= airport_details
    query_sections = Array.new
    
    if routes_unhighlighted.any?
      query_sections.push("c:%23FF7777")
      query_sections.push(gcmap_route_string(routes_unhighlighted))
    end
    
    if routes_normal.any? || routes_highlighted.any?
      
      query_sections.push("c:red")
      
      # Add normal routes:
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

  # Creates a Great Circle Mapper querystring from a list of airports.
  #
  # @param airports [Array<Number>] airport IDs
  # @return [String] a comma-separated string of IATA codes
  def gcmap_airport_string(airports)
    return airports.map{|a| @airport_details[a][:iata]}.join(",")
  end

  # Create an array of IATA codes preceeded by appropriate Great Circle
  # Mapper-formatted airport disc sizes.
  #
  # @param frequencies [Hash{Number => Number}] A hash with airport IDs for
  #   keys and number of visits for values
  # @return [String] a Great Circle Mapper querystring
  def gcmap_airport_frequency_rings_string(frequencies)
    
    max_gcmap_ring = 99 # Define the maximum ring size gcmap will allow
    previous_airport_value = nil
    frequency_max = 1.0
    frequency_scaled = 0
    
    query = Array.new      
    iata_frequencies = Array.new
    
    airports_normal.each do |airport|
      iata_frequencies.push(iata_code: @airport_details[airport][:iata], frequency: frequencies[airport])
    end
    iata_frequencies.sort_by! { |airport| [-airport[:frequency], airport[:iata_code]] }
    
    iata_frequencies.each do |airport|
      if airport == iata_frequencies.first
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

  # Create a Great Circle Mapper querystring from a list of routes.
  #
  # @param routes [Array<Array>] an array of routes in the form of
  #   [[airport_1_id, airport_2_id]]
  # @return [String] comma-separated sets of hyphen-separated IATA code pairs
  def gcmap_route_string(routes)
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
        route_groups.push(@airport_details[airport_id][:iata] + "-" + matching.map{|x| @airport_details[x[0] == airport_id ? x[1] : x[0]][:iata]}.sort.join("/")) # The map with ternary statement is used to ensure we keep routes where both airports are the same; otherwise we could just use flatten and reject.
      end
    end
    return route_groups.join(",")
  end

  # GPX METHODS

  # Appends a GPX waypoint for a specific airport to an XML object.
  #
  # @param airport_id [Number] an airport ID
  # @param wpt_type [Symbol] the GPX waypoint type to use (e.g. :wpt, :rtept,
  #   :trkpt)
  # @param xml [Object] The Nokogiri XML Builder object to append to
  # @return [nil]
  def gpx_airport(airport_id, wpt_type, xml)
    detail = @airport_details[airport_id]
    xml.send(wpt_type, lat: detail[:latitude], lon: detail[:longitude]){
      xml.name([detail[:iata], detail[:icao]].join(" / "))
      xml.description(detail[:city])
    }
    return nil
  end

  # KML METHODS

  # Appends a KML folder for a collection of routes to an XML object.
  # 
  # @param routes [Array<Number>] an array of routes in the form of
  #   [[airport_1_id, airport_2_id]]
  # @param name [String] the folder name
  # @param xml [Object] The Nokogiri XML Builder object to append to
  # @return [nil]
  def kml_routes(routes, name, xml)
    return nil unless routes.any?
    routes = routes.map{|r| r.sort_by{|x| @airport_details[x][:iata]}}.uniq.sort_by{|y| [@airport_details[y[0]][:iata], @airport_details[y[1]][:iata]]}
    
    xml.Folder do
      xml.name_(name)
      routes.each do |route|
        detail = route.map{|airport| @airport_details[airport]}
        xml.Placemark do
          xml.name_(detail.map{|a| a[:iata]}.join("–"))
          xml.styleUrl("#flightPath")
          xml.LineString do
            xml.tessellate("1")
            xml.coordinates(detail.map{|a| "#{a[:longitude]},#{a[:latitude]},0"}.join(" "))
          end
        end
      end
    end
    return nil
  end
  
end