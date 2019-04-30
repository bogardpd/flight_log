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
  
  def format_airport_name(airport_name)
    return airport_name.gsub(" (", %Q(&ensp;<small class="airport-name">)).gsub(")", "</small>").html_safe
  end
  
  def format_coordinates(coordinates)
    return "#{"%.5f" % coordinates[0].abs}° #{coordinates[0] < 0 ? "S" : "N"}&ensp;#{"%.5f" % coordinates[1].abs}° #{coordinates[1] < 0 ? "W" : "E"}".html_safe
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
  
  def airline_icon(icao_code, title: nil, css_class: nil)
    return image_tag("assets/blank.png", class: "airline-icon") unless icao_code
    icao_code = icao_code.upcase
    title ||= icao_code
    class_array = ["airline-icon"]
    class_array |= css_class.split(" ") if css_class
    return image_tag("#{ExternalImage::ROOT_PATH}/flights/airline-icons/icao/#{icao_code}.png", title: title, alt: icao_code, class: class_array.join(" "), onerror: "this.src='assets/blank.png';this.onerror='';").html_safe
  end
  
  def country_flag_icon(country, title: nil)
    return image_tag("/assets/blank.png", class: "country-flag-icon") unless country
    title ||= country
    return image_tag("#{ExternalImage::ROOT_PATH}/flights/country-flags/#{country.downcase.gsub(/\s+/, "-").gsub(/[^a-z0-9_-]/, "").squeeze("-")}.png", title: title, class: "country-flag-icon", onerror: "this.src='assets/blank.png';this.onerror='';").html_safe
    html += %Q(</span>)
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
    country_flag_icon(TailNumber.country(tail_number))
  end
  
  def tail_number_with_country_flag(tail_number, show_flag_without_country=true)
    country_format = TailNumber.country_format(tail_number)
    tail_link = link_to(country_format[:tail], show_tail_path(tail_number), title: "View flights on tail number #{country_format[:tail]}")
    if country_format[:country] || show_flag_without_country
      return "#{country_flag_icon(country_format[:country])} #{tail_link}".html_safe
    else
      return tail_link.html_safe
    end
  end
  
  
  # GREAT CIRCLE MAPPER HELPER FUNCTIONS
  
  # Create HTML for a map with region select tabs.
  # 
  # @param map [Map] the map to show
  # @param selected_region [Array] the currently active region as an array of
  #   ICAO prefixes (e.g. ["K","PH"])
  # @option [String] :anchor (nil) a page anchor position for the region select links to link to
  # @return [ActiveSupport::SafeBuffer] HTML for a map with region select tabs
  def map_with_region_select(map, selected_region, anchor: nil)
    return content_tag(:div, id: anchor) do
      if map && map.exists?
        concat gcmap_region_select_links(map, selected_region, anchor: anchor)
        concat map.gcmap
      else
        if selected_region.length > 0
          concat render_message(:warning, "Paul has taken no flights in #{"region".pluralize(selected_region.count)} #{selected_region.join(", ")}.")
        else
          concat render_message(:warning, "When flights have been added, you’ll see a map here.")
        end
      end
    end
  end
    
  # Create region select tabs.
  # 
  # @param map [Map] the map to show
  # @param selected_region [Array] the currently active region as an array of
  #   ICAO prefixes (e.g. ["K","PH"])
  # @option [String] :anchor (nil) a page anchor position for the region select links to link to
  # @return [ActiveSupport::SafeBuffer] HTML region select tabs
  def gcmap_region_select_links(map, selected_region, anchor: nil)
    region_hash = map.gcmap_regions(selected_region)
    tabs = Array.new
    
    region_hash.each do |region, values|
      if values[:selected]
        tabs.push(content_tag(:li, region, class: "selected"))
      else
        tabs.push(content_tag(:li, link_to(region, url_for(params.permit(:id, :sort).merge(region: values[:icao].join("-"), anchor: anchor)))))
      end
    end
    
    if tabs.length > 1
      return content_tag(:div, content_tag(:ul, safe_join(tabs), class: "region-select"), class: "region-select")
    else
      return ""
    end
    
    
  end
  
end
