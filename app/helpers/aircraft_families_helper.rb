# Defines helper methods for {AircraftFamily} views.
module AircraftFamiliesHelper

  # Formats an aircraft manufacturer and family.
  # 
  # @param manufacturer [String] an aircraft manufacturer
  # @param family [String] an aircraft family
  # @return [ActiveSupport::SafeBuffer] a formatted aircraft manufacturer and family
  def format_aircraft_family(manufacturer, family)
    return content_tag(:span, manufacturer, class: "aircraft-manufacturer") + " " + family
  end

  # Adds breadcrumbs for the current aircraft type and all its ancestor aircraft
  # types. The highest ancestor type will include the manufacturer name, and all
  # others will only show the type name.
  def type_and_parent_types_breadcrumbs(type)
    types = type.type_and_parent_types.reverse
    add_breadcrumb(types.first.full_name, aircraft_family_path(types.first.slug))
    types[1..-1].each do |t|
      add_breadcrumb(t.name, aircraft_family_path(t.slug))
    end
  end

end