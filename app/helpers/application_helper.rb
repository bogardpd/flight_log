module ApplicationHelper
  
  def title_flight_log
    base_title = "Paul Bogardʼs Flight Historian"
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
  
  def render_message(type, text)
    render partial: "layouts/message", locals: {type: type, text: text}
  end
  
  def render_messages
    order = [:error, :warning, :success, :info]
    @messages ||= []
    @messages.concat(flash.map{|k,v| {type: k.to_sym, text: v}}) if flash
    @messages.sort_by{|m| order.index(m[:type]) || order.length}.map{|m| render_message(m[:type], m[:text]) }.join.html_safe
  end
  
  def iata_airline_code_display(iata_airline_code)
    iata_airline_code.split('-').first
  end
  
  def country_flag(country)
    image_tag(Airport.new(:country => country).country_flag_path, :title => country, :alt => country, :class => 'country_flag')
  end
  
  def distance_block(distance, adjective: nil, flight_link: nil)
    html = "<p class=\"distance\">" + distance_string(distance, adjective)
    if flight_link
      html += " &middot; " + link_to('See a list of these flights', '#flights')
    end
    html += "</p>"
    html.html_safe
  end
  
  def distance_string(distance, adjective = nil)
    html = pluralize("<span class=\"distance_primary\">" + number_with_delimiter(distance, :delimiter => ','), [adjective,'mile'].join(' ')) + "</span> <span class=\"distance_secondary\">(" + number_with_delimiter((distance*1.60934).to_i, :delimiter => ',') + " km)</span>"
    html.html_safe
  end
  
  def code_mono(code)
    return nil unless code.present?
    html = "<span class=\"code-mono\">" + code + "</span>"
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
      sort_direction = ['-','']
    else
      sort_dir_string = ['asc','desc']
      sort_direction = ['','-']
    end
    if (@sort_cat == sort_symbol && @sort_dir == default_dir)
      sort_polarity = sort_direction[0]
    else
      sort_polarity = sort_direction[1]
    end
    link_to([title_string,category_sort_symbol].join(" ").html_safe, url_for(region: params[:region],  sort: sort_polarity.to_s + sort_string, :anchor => page_anchor), :class => "sort")
  end
  
  def tail_number_country_flag(tail_number)
    country_flag(TailNumber.country(tail_number))
  end
  
  # GREAT CIRCLE MAPPER HELPER FUNCTIONS
  
  # Return a region select menu, along with a map.
  # Params:
  # +region+:: The currently active region
  # +anchor+:: If set, defines a page anchor position for the region select links to link to
  def map_with_region_select(map, anchor: nil)
    html = %Q(<div id="#{anchor}">\n)
    if map && map.exists?
      html += gcmap_region_select_links(@region, anchor: anchor)
      html += map.draw
    else
      html += render_message(:warning, "When flights have been added, you’ll see a map here.")
    end
    html += "</div>\n"
    html.html_safe
  end
    
  # Return a menu allowing the user to switch between regions on a map
  # Params: 
  # +region+:: The currently active region
  def gcmap_region_select_links(region, anchor: nil)
    html = "<div class=\"region_select\">"
    html += "<ul class=\"region_select\">"
    if region == :conus
    	html += "<li>"
      html +=	link_to("World", url_for(region: :world, anchor: anchor, sort_category: params[:sort_category], sort_direction: params[:sort_direction]))
      html += "</li><li class=\"selected\">Contiguous United States</li>"
    else
    	html += "<li class=\"selected\">World</li><li>"
      html += link_to("Contiguous United States", url_for(region: :conus, anchor: anchor, sort_category: params[:sort_category], sort_direction: params[:sort_direction]))
      html += "</li>"      	
    end
    html += "</ul></div>"
  end
  
end
