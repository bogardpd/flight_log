# Defines helper methods for {AircraftFamily} views.
module AircraftFamiliesHelper

  # Formats an aircraft manufacturer and family.
  # 
  # @param manufacturer [String] an aircraft manufacturer
  # @param family [String] an aircraft family
  # @return [ActiveSupport::SafeBuffer] a formatted aircraft manufacturer and family
  def format_aircraft_family(manufacturer, family)
    return [manufacturer, family].join(" ")
  end

  # Adds breadcrumbs for the current aircraft type and all its ancestor aircraft
  # types.
  def type_and_parent_types_breadcrumbs(type)
    types = type.type_and_parent_types.reverse
    types.each do |t|
      add_breadcrumb(t.full_name, aircraft_family_path(t.slug))
    end
  end

end