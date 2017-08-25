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
      %Q(<meta name="description" content="#{@meta_description}" />).html_safe
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
    iata_airline_code.split("-").first
  end
  
  def country_flag(country)
    image_tag(Airport.new(:country => country).country_flag_path, :title => country, :alt => country, :class => "country_flag")
  end
  
  def code_mono(code)
    return nil unless code.present?
    html = %Q(<span class="code-mono">#{code}</span>)
    html.html_safe
  end
  
  def sort_link(title_string, sort_symbol, sort_string, default_dir, page_anchor)
        
    if @sort_cat == sort_symbol
      if @sort_dir == :asc
        category_sort_symbol = %Q(<span class="sort-symbol">&#x25B2;</span>) # Up Triangle
      elsif @sort_dir == :desc
        category_sort_symbol = %Q(<span class="sort-symbol">&#x25BC;</span>) # Down Triangle
      end
    else
      category_sort_symbol = ""
    end
    
    case default_dir
    when :asc
      sort_dir_string = ["desc","asc"]
      sort_direction = ["-",""]
    else
      sort_dir_string = ["asc","desc"]
      sort_direction = ["","-"]
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
  # +map+:: The map to show
  # +selected_region+:: The currently active region
  # +anchor+:: If set, defines a page anchor position for the region select links to link to
  def map_with_region_select(map, selected_region, anchor: nil)
    html = String.new
    html << %Q(<div id="#{anchor}">\n)
    if map && map.exists?
      html << gcmap_region_select_links(map, selected_region, anchor: anchor)
      html << map.draw
    else
      if selected_region.length > 0
        html << render_message(:warning, "Paul has taken no flights in #{"region".pluralize(selected_region.count)} #{selected_region.join(", ")}.")
      else
        html << render_message(:warning, "When flights have been added, you’ll see a map here.")
      end
    end
    html << "</div>\n"
    html.html_safe
  end
    
  # Return a menu allowing the user to switch between regions on a map
  # Params: 
  # +region+:: The currently active region
  def gcmap_region_select_links(map, selected_region, anchor: nil)
    regions = Hash.new
    regions["World"]       = %w()
    regions["USA (CONUS)"] = %w(K)
    regions["Europe"]      = %w(B E L)
    
    used_airports = map.used_airports
    
    html = String.new
    html << %Q(<div class="region-select">)
    html << %Q(<ul class="region-select">)
    
    regions.each do |name, icao|
      if selected_region.uniq.sort == icao.uniq.sort
        html << %Q(<li class="selected">#{name}</li>)
      else
        unless (Airport.in_region(icao) & used_airports).empty?
          
          html << "<li>"
          html << link_to(name, url_for(params.permit(:sort).merge(region: icao.join("-"), anchor: anchor)))
          html << "</li>"
        end
        
      end 
    end
    
    html << "</ul></div>"
  end
  
end
