# Defines a latitude, longitude coordinate.

class Coordinate

  # Initialize a coordinate.
  # 
  # @param latitude [Float] latitude in decimal degrees
  # @param longitude [Float] longitude in decimal degrees
  def initialize(latitude, longitude)
    if latitude < -90 || latitude > 90
      raise ArgumentError.new("Latitude must be between -90 and 90 degrees (inclusive)")
    end
    if longitude < -180 || longitude > 180
      raise ArgumentError.new("Longitude must be between -180 and 180 degrees (inclusive)")
    end
    @latitude = latitude.to_f
    @longitude = longitude.to_f
  end

  # Prints the coordinate.
  # 
  # @return [String] coordinate
  def to_s
    return "(#{'%.6f' % @latitude}, #{'%.6f' % @longitude})"
  end

  # Returns the coordinate's latitude.
  #
  # @return [Float] latitude
  def lat
    return @latitude
  end

  # Returns the coordinate's longitude.
  #
  # @return [Float] longitude
  def lon
    return @longitude
  end

end