# Provides utilities for dealing with great circle paths.
module GreatCircle

  # Given two {Coordinates}, returns the points of the great circle
  # path between them at a specified interval.
  #
  # @param coord_orig [Coordinate] origin
  # @param coord_dest [Coordinate] destination
  # @param deg_interval [Float] the spacing between path points in degrees
  # @param split [Boolean] whether to split the path at the antimeridian (180 degrees longitude)
  # @return [Array<Array>] an array of arrays of {Coordinates}
  def self.gc_route_coords(coord_orig, coord_dest, deg_interval=1.0, split=true)
    phi1, lambda1 = deg_to_rad(coord_orig.lat), deg_to_rad(coord_orig.lon)
    phi2, lambda2 = deg_to_rad(coord_dest.lat), deg_to_rad(coord_dest.lon)
    
    # Determine spherical parameters.
    lambda12 = normalize_longitude(lambda2 - lambda1)
    alpha1 = Math.atan2(
      (Math.cos(phi2) * Math.sin(lambda12)),
      ((Math.cos(phi1) * Math.sin(phi2)) - (Math.sin(phi1) * Math.cos(phi2) * Math.cos(lambda12)))
    )
    alpha2 = Math.atan2(
      (Math.cos(phi1) * Math.sin(lambda12)),
      (-(Math.cos(phi2) * Math.sin(phi1)) + (Math.sin(phi2) * Math.cos(phi1) * Math.cos(lambda12)))
    )
    sigma12 = Math.atan2(
      Math.sqrt(
        (Math.cos(phi1) * Math.sin(phi2) - Math.sin(phi1) * Math.cos(phi2) * Math.cos(lambda12)) ** 2 \
        + (Math.cos(phi2) * Math.sin(lambda12)) ** 2
      ),
      (Math.sin(phi1) * Math.sin(phi2) + Math.cos(phi1) * Math.cos(phi2) * Math.cos(lambda12))
    )
    alpha0 = Math.atan2(
      Math.sin(alpha1) * Math.cos(phi1),
      Math.sqrt(Math.cos(alpha1) ** 2 + (Math.sin(alpha1) ** 2) * (Math.sin(phi1) **2))
    )
    if phi1 == 0 && alpha1 = Math::PI / 2
      sigma01 = 0
    else
      sigma01 = Math.atan2(Math.tan(phi1), Math.cos(alpha1))
    end
    sigma02 = sigma01 + sigma12
    lambda01 = Math.atan2(Math.sin(alpha0) * Math.sin(sigma01), Math.cos(sigma01))
    lambda0 = lambda1 - lambda01

    # Create range of sigma values to calculate coordinates for.
    num_points = (rad_to_deg(sigma12) / deg_interval).round()
    steps = (sigma01..sigma02).step(sigma12/num_points)

    # Calculate coordinates.
    coords = []
    steps.each do |sigma|
      lat = rad_to_deg(Math.atan2(
        Math.cos(alpha0) * Math.sin(sigma),
        Math.sqrt((Math.cos(sigma) ** 2) + (Math.sin(alpha0) ** 2) * (Math.sin(sigma) ** 2)))
      )
      lon = rad_to_deg(
        normalize_longitude(
          Math.atan2(Math.sin(alpha0) * Math.sin(sigma), Math.cos(sigma)) + lambda0
        )
      )
      coords.append(Coordinate.new(lat, lon))
    end

    if split
      # Check if route crosses antimeridian, and split it into two if it does.
      # Use the first and last items of the coordinates array to avoid rounding
      # issues.
      heading1 = alpha1 % (2*Math::PI)
      if (coords[0].lon > coords[-1].lon && heading1 < Math::PI) || (coords[0].lon < coords[-1].lon && heading1 > Math::PI)
        # Route crosses antimeridian.
        # Calculate the latitude of the antimeridian crossing.
        sigma_am = Math.atan2(Math.tan(Math::PI - lambda0), Math.sin(alpha0))
        lat_am = rad_to_deg(Math.atan2(
          Math.cos(alpha0) * Math.sin(sigma_am),
          Math.sqrt((Math.cos(sigma_am) ** 2) + (Math.sin(alpha0) ** 2) * (Math.sin(sigma_am) ** 2)))
        )
        # Split the route into two, and add the antimeridian point to each part.
        if coords[0].lon > coords[-1].lon
          coords1, coords2 = coords.partition{|c| c.lon >= coords[0].lon }
          coords1.insert(-1, Coordinate.new(lat_am,  180.0)) unless coords1[-1].lon == 180.0
          coords2.insert( 0, Coordinate.new(lat_am, -180.0)) unless coords2[0].lon == -180.0
        else
          coords1, coords2 = coords.partition{|c| c.lon <= coords[0].lon }
          coords1.insert(-1, Coordinate.new(lat_am, -180.0)) unless coords1[-1].lon == -180.0
          coords2.insert( 0, Coordinate.new(lat_am,  180.0)) unless coords2[0].lon == 180.0
        end
        multipath_coords = [coords1, coords2]
      else
        # Route does not cross antimeridian.
        multipath_coords = [coords]
      end
    else
      # Coords will be a multilinestring with a single line.
      multipath_coords = [coords]
    end

    return multipath_coords
  end

  # Converts degrees to radians.
  # 
  # @param deg [Float] degrees
  # @return [Float] radians
  def self.deg_to_rad(deg)
    return deg * Math::PI / 180
  end

  # Converts radians to degrees.
  # 
  # @param rad [Float] radians
  # @return [Float] degrees
  def self.rad_to_deg(rad)
    return rad * 180 / Math::PI
  end

  # Ensures a longitude is between -π and π rad (-180° to 180°).
  #
  # @param rad [Float] a longitude in radians
  # @return [Float] a normalized longitude in radians
  def self.normalize_longitude(rad)    
    while rad > Math::PI
      rad -= 2 * Math::PI
    end
    while rad < -(Math::PI)
      rad += 2 * Math::PI
    end
    return rad
  end

end