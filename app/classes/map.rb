class Map
  include ActionView::Helpers
  
  def draw
        
    html = %Q(<div class="center">)
    #html += link_to(image_tag("http://www.gcmap.com/map?PM=#{airport_options}&MP=r&MS=wls2&P=#{query}", :alt => "Map of flight routes", :class => "photo_gallery"), "http://www.gcmap.com/mapui?PM=#{airport_options}&MP=r&MS=wls2&P=#{query}")
    html += link_to(image_tag(Rails.application.routes.url_helpers.gcmap_image_path(airport_options, query, Map.hash_image_query(query)), :alt => alt_tag, :class => "photo_gallery"), "http://www.gcmap.com/mapui?PM=#{airport_options}&MP=r&MS=wls2&P=#{query}")
    html += "</div>\n"
    
    return html.html_safe
    
  end
  
  def exists?
    query.present?
  end
  
  def includes_region?(region)
    # Returns true if this map has any flights or listed airports within the given region.
    # Allows the region select links to decide whether to show a particular region's link.
    # Not yet implemented, will be implemented when additional regions are added.
    return false
  end
  
  # Return a hash of a map query based on a secret key
  # Params: 
  # +query+:: The query to hash
  def self.hash_image_query(query)
    Digest::MD5.hexdigest(query + ENV["IMAGE_KEY"])
  end
  
  private
  
    def airport_options
      return "b:disc5:black"
    end
    
    def alt_tag
      return "Map of flight routes"
    end
      
    def routes_inside_region
      return Array.new
    end
  
    def routes_outside_region
      return Array.new
    end
  
    def routes_highlighted
      return Array.new
    end
    
    def routes_unhighlighted
      return Array.new
    end
  
    def airports_inside_region
      return Array.new
    end
  
    def airports_highlighted
      return Array.new
    end
    
    def airports_frequency
      return Array.new
    end
  
    def query
      query_sections = Array.new
      
      if routes_outside_region.any? || routes_unhighlighted.any?
        
        query_sections.push("c:%23FF7777")
        
        # Add routes outside region:
        if routes_outside_region.any?
          query_sections.push("o:noext")
          query_sections.push(routes_outside_region.join(",o:noext,"))
        end
      
        # Add unhighlighted routes:
        if routes_unhighlighted.any?
          query_sections.push(routes_unhighlighted.join(","))
        end
        
      end
      
      if routes_inside_region.any? || routes_highlighted.any?
        
        query_sections.push("c:red")
        
        # Add routes inside region:
        if routes_inside_region.any?
          query_sections.push(routes_inside_region.join(","))
        end
      
        # Add highlighted routes:
        if routes_highlighted.any?
          query_sections.push("w:2")
          query_sections.push(routes_highlighted.join(","))
        end
      
      end
      
      # Add airports:
      if airports_inside_region.any?
        query_sections.push(airports_inside_region.join(","))
      end
      
      # Add highlighted airports:
      if airports_highlighted.any?
        if @include_names
          query_sections.push(%Q(m:p:ring11:black%2B"%25N"12r%3A%23666))
        else
          query_sections.push("m:p:ring11:black")
        end
        query_sections.push(airports_highlighted)
      end
      
      # Add frequency rings:
      if airports_frequency.any?
        query_sections.push(airports_frequency.join(","))
      end
            
      return query_sections.join(",")
    end
    
    # Convert a set of pairs into a Great Circle Mapper formatted querystring, minimizing string length.
    # Params:
    # +pairs+:: An array of arrays of two IATA codes.
    def compressed_routes(pairs)
      routes = Array.new
      pairs = pairs.uniq.sort_by{|k| [k[0],k[1]]}
      previous_origin = nil
      route_string = nil
      pairs.each do |pair|
        if pair[0] == previous_origin && route_string
          route_string += "/#{pair[1]}"
        else
          routes.push(route_string) if route_string
          route_string = "#{pair[0]}-#{pair[1]}"
        end
        routes.push(route_string) if (pair == pairs.last && route_string)
        previous_origin = pair[0]
      end
      return routes
    end
  
end