class Map
  include ActionView::Helpers
  include Rails.application.routes.url_helpers
  
  def draw
    # TO DO: Load image from URL and place into HTTPS wrapper
    
    if query.present?
      
      html = %Q(<div class="center">)
      html += link_to(image_tag("http://www.gcmap.com/map?PM=#{airport_options}&MP=r&MS=wls2&P=#{query}", :alt => "Map of flight routes", :class => "photo_gallery"), "http://www.gcmap.com/mapui?PM=#{airport_options}&MP=r&MS=wls2&P=#{query}")
      html += "</div>\n"
    
      return html.html_safe
    end
    
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