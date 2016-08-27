class Map
  include ActionView::Helpers
  
  def draw
    # TO DO: Load image from URL and place into HTTPS wrapper
    
    html = %Q(<div class="center">)
    html += link_to(image_tag("http://www.gcmap.com/map?PM=#{airport_options}&MP=r&MS=wls2&P=#{query}", :alt => "Map of flight routes", :class => "photo_gallery"), "http://www.gcmap.com/mapui?PM=#{airport_options}&MP=r&MS=wls2&P=#{query}")
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
  
  private
  
    def airport_options
      "b:disc5:black"
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
  
    def airports_inside_region
      return Array.new
    end
  
    def airports_outside_region
      return Array.new
    end
  
    def airports_highlighted
      return Array.new
    end
  
    def query
      query_sections = Array.new
      
      # Add routes outside region:
      if routes_outside_region.any?
        query_sections.push("c:%23FF7777,o:noext,#{routes_outside_region.join(",o:noext,")}")
      end
      
      # Add routes inside region:
      if routes_inside_region.any?
        query_sections.push("c:red,#{routes_inside_region.join(",")}")
      end
      
      return query_sections.join(",")
    end
    
    
  
end