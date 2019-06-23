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

end