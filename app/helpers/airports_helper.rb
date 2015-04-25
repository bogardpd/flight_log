module AirportsHelper
  
  def gcmap_airport_embed(airport_array, *args)
    # Accept an array with :iata_code, and embed a map of airports.
    @gcmap_used = true
    map_center = args[0] == "world" ? "" : ""
    
    # Sort airports:
    airport_array = airport_array.sort_by { |airport| airport[:city] }

    # Generate airport location markers:
    query = "m:p:disc5:black,"
    airport_array.each do |airport|
     query += "#{airport[:iata_code]},"
    end
    query.chomp!(",")

    # Embed map:

    html = "<div class=\"center\">"
    html += link_to(image_tag("http://www.gcmap.com/map?P=#{query}&MS=wls2&PM=b:disc5:black#{map_center}", :alt => "Map of airport frequencies", :class => "photo_gallery"), "http://www.gcmap.com/mapui?PM=b:disc5:black&MS=wls2#{map_center}&P=#{query}")
    html += "</div>"
    html.html_safe
  end

  def gcmap_airport_frequency_embed(airport_array, *args)
    # Accept an array with :iata_code and :frequency, and embed a map of airport frequencies
    @gcmap_used = true
    map_center = args[0] == "world" ? "" : ""
    
    # Sort airports by descending frequency value:
    airport_array = airport_array.sort_by { |airport| [-airport[:frequency], airport[:city]] }
  
    max_gcmap_ring = 99 # Define the maximum ring size gcmap will allow
  
    # Generate airport location markers:
    query = "m:p:disc5:red,"
    airport_array.each do |airport|
      query += "#{airport[:iata_code]},"
    end
    # Generate airport frequency circles:
    previous_airport_value = ""
    frequency_max = 1.0
    frequency_scaled = 0
    airport_array.each_with_index do |airport, index|
      if index == 0
        # This is the first circle, so define its color:
        query += "m:p:ring#{max_gcmap_ring}:black,#{airport[:iata_code]},"
        frequency_max = airport[:frequency].to_f
      elsif airport[:frequency] == previous_airport_value
        # Value is the same as previous, so no need to define circle size:
        query += "#{airport[:iata_code]},"
      else
        frequency_scaled = Math.sqrt((airport[:frequency].to_f / frequency_max)*(max_gcmap_ring**2)).ceil.to_i # Scale frequency range from 1..max_gcmap_ring
        query += "m:p:ring#{frequency_scaled},#{airport[:iata_code]},"
      end
      previous_airport_value = airport[:frequency]
    end
    query.chomp!(",")

    # Embed map:

    html = "<div class=\"center\">"
    html += link_to(image_tag("http://www.gcmap.com/map?P=#{query}&MS=wls2&PM=b:disc5:black#{map_center}", :alt => "Map of airport frequencies", :class => "photo_gallery"), "http://www.gcmap.com/mapui?PM=b:disc5:black&MS=wls2#{map_center}&P=#{query}")
    html += "</div>"
    html.html_safe
  end
  
  
  
end
