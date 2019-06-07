# Provides utilities for interacting with travel classes.
module TravelClass
  
  # Returns an array of airlines, with a hash for each family containing the
  # class code and number of flights in that class, sorted by class quality descending.

  # Returns an array of travel classes, class codes, and number of {Flight
  # Flights} in that travel class, sorted by number of flights descending.
  #
  # Used on various "index" and "show" views to generate a table of travel
  # classes and their flight counts.
  #
  # @param flights [Array<Flight>] a collection of {Flight Flights} to
  #   calculate travel class flight counts for
  # @return [Array<Hash>] details for each travel class flown
  def self.flight_count(flights)
    counts = flights.reorder(nil).group(:travel_class).count
      .map{|k,v| {class_code: k, flight_count: v}}
    
    class_sum = counts.reduce(0){|sum, f| sum + f[:flight_count]}
    if flights.count > class_sum
      counts.push({class_code: nil, flight_count: flights.count - class_sum})
    end
    return counts.sort_by{|tc| list[tc[:class_code]]&.dig(:quality) || -1}.reverse
  end
  
  # Given a travel class name, gets the travel class code.
  #
  # @param class_string [String] a travel class name
  # @return [String] a travel class code
  def self.get_class_id(class_string)
    return nil unless class_string.present?
    classes = list.invert
    return classes[class_string.split.map{|t| t.capitalize}.join(" ")]
  end
  
  # Returns a hash of travel classes, descriptions, and quality ratings.
  #
  # @return [Hash] travel class details
  def self.list
    classes = Hash.new
    classes["first"] = {
      name: "First",
      description: "Highest class on planes with both First and Business",
      quality: 5
    }
    classes["business"] = {
      name: "Business",
      description: "Highest class on planes without separate First and Business",
      quality: 4
    }
    classes["premium-economy"] = {
      name: "Premium Economy",
      description: "Economy with extra legroom and seat width",
      quality: 3
    }
    classes["economy-extra"] = {
      name: "Economy Extra",
      description: "Economy with extra legroom",
      quality: 2
    }
    classes["economy"] = {
      name: "Economy",
      description: "Standard main cabin seat",
      quality: 1
    }
    return classes
  end

  # Returns an array of travel classes in a format ready for
  # +options_for_select+. Used for generating travel class select boxes for the
  # {FlightsController#new new} and {FlightsController#edit edit} flight forms.
  # 
  # @return [Array<Array>] options for a travel class select box
  def self.dropdown
    return self.list.map{|k,v| ["#{v[:name]} (#{v[:description]})", k]}
  end
  
  # Accepts a flyer, the current user, and a date range, and returns all
  # classes that had their first flight in this date range.

  # Accepts a flyer, the viewing user, and date range, and returns all travel
  # classes that had their first flight in this date range. Used on
  # \{FlightsController#show_date_range} to highlight new travel classes.
  #
  # @param flyer [User] the {User} whose flights should be searched
  # @param current_user [User, nil] the {User} viewing the flights
  # @param date_range [Range<Date>] the date range to search
  # @return [Array<String>] an array of travel class IDs
  def self.new_in_date_range(flyer, current_user, date_range)
    flights = flyer.flights(current_user).reorder(nil)
    first_flights = flights.select(:travel_class, :departure_date).where.not(travel_class: nil).group(:travel_class).minimum(:departure_date)
    return first_flights.select{|k,v| date_range.include?(v)}.map{|k,v| k}.sort
  end  
  
end