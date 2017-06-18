module TravelClass
  
  # Returns an array of airlines, with a hash for each family containing the
  # class code and number of flights in that class.
  def self.flight_count(logged_in=false, flights: nil)
    flights ||= Flight.all
    flights = flights.visitor unless logged_in
    counts = flights.group(:travel_class).count
      .map{|k,v| {class_code: k, flight_count: v}}
    
    class_sum = counts.reduce(0){|sum, f| sum + f[:flight_count]}
    if flights.count > class_sum
      counts.push({class_code: nil, flight_count: flights.count - class_sum})
    end
    return counts
  end
  
  # Returns a hash of travel classes.
  def self.list
    classes = Hash.new
    classes["F"] = "First"
    classes["J"] = "Business"
    classes["W"] = "Premium Economy"
    classes["Y"] = "Economy"
    return classes
  end
  
  # Given a travel class string, gets the travel class code.
  def self.get_class_id(class_string)
    return nil unless class_string.present?
    classes = list.invert
    return classes[class_string.split.map{|t| t.capitalize}.join(" ")]
  end
  
end