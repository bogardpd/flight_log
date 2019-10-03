# Provides utilities for calculating distances.
module Distance
  
  # The number of kilometers in a statute mile.
  KM_PER_MILE = 1.60934

  # Converts distances from miles to kilometers.
  # 
  # @param miles [Integer] a distance in miles
  # @return [Integer] a distance in kilometers
  def self.km(miles)
    return (miles * KM_PER_MILE).to_i
  end
  
end