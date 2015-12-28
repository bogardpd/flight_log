module ApplicationHelper
  
  def title_flight_log
    base_title = "Paul Bogard's Flight Log"
    if @title.nil?
      base_title
    else
      "#{@title} - #{base_title}"
    end
  end  
  
  def meta_description
    if @meta_description.nil?
      ""
    else
      "<meta name=\"description\" content=\"#{@meta_description}\" />".html_safe
    end
  end
  
  def airline_icon_path(iata_airline_code)
    image_location = "airline_icons/" + iata_airline_code + ".png"
    if Rails.application.assets.find_asset(image_location)
      image_location
    else
      "airline_icons/unknown-airline.png"
    end
  end
  
  def iata_airline_code_display(iata_airline_code)
    iata_airline_code.split('-').first
  end
  
  def country_flag(country)
    image_tag(Airport.new(:country => country).country_flag_path, :title => country, :class => 'country_flag')
  end
  
  
  def download_link(title, path)
    html = "<ul><li>Download: " + link_to(title, path) + "</li></ul>"
    html.html_safe
  end
  
  def distance_block(distance, adjective = nil)
    html = "<p class=\"distance\">" + distance_string(distance, adjective) + "</p>"
    html.html_safe
  end
  
  def distance_string(distance, adjective = nil)
    html = pluralize("<span class=\"distance_primary\">" + number_with_delimiter(distance, :delimiter => ','), [adjective,'mile'].join(' ')) + "</span> <span class=\"distance_secondary\">(" + number_with_delimiter((distance*1.60934).to_i, :delimiter => ',') + " km)</span>"
    html.html_safe
  end
  
  def format_date(input_date) # Also see method in application controller
    input_date.strftime("%e %b %Y")
  end
  
  def gcmap_embed(route_string, *args)
    @gcmap_used = true
    map_center = args[1] == "world" ? "" : ""
    if args[0] == "labels"
      query_pm = "*"
    else
      query_pm = "b:disc5:black"
    end
    html = "<div class=\"center\">"
    html += link_to(image_tag("http://www.gcmap.com/map?PM=#{query_pm}&MP=r&MS=wls2#{map_center}&P=#{route_string}", :alt => "Map of flight routes", :class => "photo_gallery"), "http://www.gcmap.com/mapui?PM=#{query_pm}&MP=r&MS=wls2#{map_center}&P=#{route_string}")
    html += "</div>"
    html.html_safe
  end
  
  def iata_mono(code)
    html = "<span class=\"iata_mono\">" + code + "</span>"
    html.html_safe
  end

  
  def sort_link(title_string, sort_symbol, sort_string, default_dir, page_anchor)
        
    if @sort_cat == sort_symbol
      if @sort_dir == :asc
        category_sort_symbol = "<span class=\"sort_symbol\">&#x25B2;</span>" # Up Triangle
      elsif @sort_dir == :desc
        category_sort_symbol = "<span class=\"sort_symbol\">&#x25BC;</span>" # Down Triangle
      end
    else
      category_sort_symbol = ""
    end
    
    case default_dir
    when :asc
      sort_dir_string = ['desc','asc']
    else
      sort_dir_string = ['asc','desc']
    end
    link_to([title_string,category_sort_symbol].join(" ").html_safe, url_for(:sort_category => sort_string, :sort_direction => ((@sort_cat == sort_symbol && @sort_dir == default_dir) ? sort_dir_string[0] : sort_dir_string[1]), :anchor => page_anchor), :class => "sort")
  end
  
  def tail_number_country_flag(tail_number)
    country_flag(Flight.tail_country(tail_number))
  end
  
  # GREAT CIRCLE MAPPER HELPER FUNCTIONS
  
  # Return HTML for a hyperlinked Great Circle Mapper map image of a collection of flights
  # Params:
  # +flight_collection+:: collection of Flight objects to be mapped
  # +use_regions+:: Set to false to force disabling of the region links (all flights will be displayed)
  # The region to use will come from params[:region]. If this does not exist, it will look for a value in @default_region, and if @default_region is nill, it will default to world.
  def embed_gcmap_airports(airport_collection)
    if params[:region]
      region = params[:region].to_sym
    elsif @default_region
      region = @default_region
    else
      region = :world
    end
    
    airport_options = "b:disc5:black"
    map_center = ""
    
    if region == :conus
      airport_codes = Airport.where(id: airport_collection).where(region_conus: true).order(:iata_code).pluck(:iata_code)
    else
      airport_codes = Airport.where(id: airport_collection).order(:iata_code).pluck(:iata_code)
    end
      
    html = gcmap_region_select_links(region) + gcmap_map_link(airport_codes.join(","), airport_options, map_center)
    return html.html_safe
  end

  
  # Return HTML for a hyperlinked Great Circle Mapper map image of a collection of flights
  # Params:
  # +flight_collection+:: collection of Flight objects to be mapped
  # +use_regions+:: Set to false to force disabling of the region links (all flights will be displayed)
  # The region to use will come from params[:region]. If this does not exist, it will look for a value in @default_region, and if @default_region is nill, it will default to world.
  def embed_gcmap_flights(flight_collection, use_regions: true)
    if use_regions == false
      region = :world
    elsif params[:region]
      region = params[:region].to_sym
    elsif @default_region
      region = @default_region
    else
      region = :world
    end
    
    airport_options = "b:disc5:black"
    map_center = ""
    
    route_string = gcmap_route_string(flight_collection, region)
    
    html = ""
    
    if use_regions
      html += gcmap_region_select_links(region)
    end
    
    html += gcmap_map_link(route_string, airport_options, map_center)
    return html.html_safe
  end
  
  
  # Return HTML for a hyperlinked Great Circle Mapper map image of a single flight
  # Params:
  # +flight_route+:: array of two airport IATA codes. If more than two codes are used, any codes beyond the first two will be ignored.
  def embed_gcmap_single_flight(flight_route)
    airport_options = "*"
    map_center = ""
    route_string = flight_route[0..1].join("-")
    return gcmap_map_link(route_string, airport_options, map_center).html_safe
  end
  
  
  # Return HTML for a hyperlinked Great Circle Mapper map image of a collection of flights with a highlighted route
  # Params:
  # +flight_collection+:: collection of Flight objects to be mapped
  # +highlighted_route+:: array of two airport IATA codes whose path between them should be highlighted. If more than two codes are used, any codes beyond the first two will be ignored.
  def embed_gcmap_route_highlight(flight_collection, highlighted_route)
    airport_options = "b:disc5:black"
    map_center = ""
    
    route_string = "c:%23FF7777,#{gcmap_route_string(flight_collection, :world, uncolored: true)},c:red,w:2,#{highlighted_route[0..1].join("-")}"
    return gcmap_map_link(route_string, airport_options, map_center).html_safe
  end
  
  # Return HTML for a hyperlinked Great Circle Mapper map image of a collection of flights with highlighted airports
  # Params:
  # +flight_collection+:: Collection of Flight objects to be mapped
  # +highlighted_airports+:: Array of airport IATA codes whose airports should be highlighted
  def embed_gcmap_airport_highlight(flight_collection, highlighted_airports)
    airport_options = "b:disc5:black"
    map_center = ""
    
    if highlighted_airports.any?
      airport_highlight_string = "m:p:ring11:black,#{highlighted_airports.join(",")},"
    else
      airport_highlight_string = ""
    end
    
    route_string = airport_highlight_string + gcmap_route_string(flight_collection, :world)
    return gcmap_map_link(route_string, airport_options, map_center).html_safe
  end
  
  
  
  # GREAT CIRCLE MAPPER STRING HELPERS:
  
  # Take a collection of flights and return a string of routes formatted for use in the Great Circle Mapper.
  # Params:
  # +flight_collection+:: collection of Flight objects to be mapped
  # +region+:: The region to focus on, or :world for all
  # +uncolored+:: Set to true to prevent automatic coloring of the route string
  def gcmap_route_string (flight_collection, region, uncolored: false)
    route_inside_region = ""
    route_outside_region = ""
    
    pairs_inside_region = Array.new
    pairs_outside_region = Array.new
    
    flight_collection.each do |flight|
      # Build array of city pairs
      if (region == :conus && (!flight.origin_airport.region_conus || !flight.destination_airport.region_conus))
        pairs_outside_region.push([flight.origin_airport.iata_code,flight.destination_airport.iata_code].sort)
      else
        pairs_inside_region.push([flight.origin_airport.iata_code,flight.destination_airport.iata_code].sort)
      end  
    end
    
    pairs_inside_region = pairs_inside_region.uniq.sort_by{|k| [k[0],k[1]]}
    pairs_outside_region = pairs_outside_region.uniq.sort_by{|k| [k[0],k[1]]}

    previous_pair0 = nil
    pairs_inside_region.each do |pair|
      if pair[0] == previous_pair0
        route_inside_region += "/#{pair[1]}"
      else
        route_inside_region += ",#{pair[0]}-#{pair[1]}"
      end
      previous_pair0 = pair[0]
    end  
    
    previous_pair0 = nil
    pairs_outside_region.each do |pair|
      if pair[0] == previous_pair0
        route_outside_region += "/#{pair[1]}"
      else
        route_outside_region += ",o:noext,#{pair[0]}-#{pair[1]}"
      end
      previous_pair0 = pair[0]
    end   
    
    if pairs_outside_region.length > 0
      route = "c:%23FF7777#{route_outside_region},c:red#{route_inside_region}"
    elsif uncolored
      route = route_inside_region
    else
      route = "c:red#{route_inside_region}"
    end
  end
  
  
  # Return a string of routes formatted for use in the Great Circle Mapper.
  # Params:
  # +route_string+:: string in Great Circle Mapper path format
  # +airport_options+:: string of Great Circle Mapper airport point formatting options
  # +map_center+:: IATA code of the airport to center the map on (leave blank if centering is not desired)
  def gcmap_map_link(route_string, airport_options, map_center)
    if map_center.length > 0
      map_center = "&MC=#{map_center}"
    end
    html = "<div class=\"center\">"
    html += link_to(image_tag("http://www.gcmap.com/map?PM=#{airport_options}&MP=r&MS=wls2#{map_center}&P=#{route_string}", :alt => "Map of flight routes", :class => "photo_gallery"), "http://www.gcmap.com/mapui?PM=#{airport_options}&MP=r&MS=wls2#{map_center}&P=#{route_string}")
    html += "</div>"
  end
  
  # Return a menu allowing the user to switch between regions on a map
  # +region+:: The currently active region
  def gcmap_region_select_links(region)
    html = "<div class=\"region_select\">"
    html += "<ul class=\"region_select\">"
    if region == :conus
    	html += "<li>"
      html +=	link_to("World", url_for(region: :world))
      html += "</li><li class=\"selected\">Contiguous United States</li>"
    else
    	html += "<li class=\"selected\">World</li><li>"
      html += link_to("Contiguous United States", url_for(region: :conus))
      html += "</li>"      	
    end
    html += "</ul></div>"
  end
  
end
