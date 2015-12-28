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
  
  # Take a collection of flights and return HTML for a hyperlinked Great Circle Mapper map image
  # Params:
  # +flight_collection+:: collection of Flight objects to be mapped
  # +use_regions+:: Set to false to force disabling of the region links (all flights will be displayed)
  # The region to use will come from params[:region]. If this does not exist, it will look for a value in @default_region, and if @default_region is nill, it will default to world.
  def gcmap_flights(flight_collection, use_regions: true)
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
      html += "<div class=\"region_select\">"
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
    
    html += "<div class=\"center\">"
    html += link_to(image_tag("http://www.gcmap.com/map?PM=#{airport_options}&MP=r&MS=wls2#{map_center}&P=#{route_string}", :alt => "Map of flight routes", :class => "photo_gallery"), "http://www.gcmap.com/mapui?PM=#{airport_options}&MP=r&MS=wls2#{map_center}&P=#{route_string}")
    html += "</div>"
    html.html_safe
  end
  
  
  # Take a collection of flights and return a string of routes formatted for use in the Great Circle Mapper.
  # Params:
  # +flight_collection+:: collection of Flight objects to be mapped
  # +region+:: The region to focus on, or :world for all
  def gcmap_route_string (flight_collection, region)
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
    else
      route = "c:red#{route_inside_region}"
    end
  end
  
end
