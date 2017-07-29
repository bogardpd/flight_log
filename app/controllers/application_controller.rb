class ApplicationController < ActionController::Base
  protect_from_forgery
  
  include SessionsHelper
  @gcmap_used = false
  
  def current_region(default: :world)
    if params[:region]
      region = params[:region].to_sym
    else
      region = default
    end
  end
  
  # Returns the user whose flights are being viewed. Until multiple user
  # functionality is added to Flight Historian, this will simply return the
  # first user.
  def flyer
    return User.first
  end
  helper_method :flyer
  
  def logged_in_user
    unless logged_in?
      redirect_to root_url
    end
  end
  
  # Get attachments from boarding pass emails
  def check_email_for_boarding_passes
    begin
      BoardingPassEmail::process_attachments(current_user.all_emails)
    rescue => details
      flash.now[:warning] = "Could not get new passes from email (#{details})"
    end
  end
  
protected

  def add_admin_action(link)
    @admin_actions ||= Array.new
    @admin_actions.push(link)
  end

  def add_breadcrumb name, url=""
    @breadcrumbs ||= []
    url = eval(url) if url =~ /_path|_url|@/
    @breadcrumbs << [name, url]
  end
  
  def self.add_breadcrumb name, url, options = {}
    before_action options do |controller|
      controller.send(:add_breadcrumb, name, url)
    end
  end
  
  def add_message(type, text)
    @messages ||= []
    @messages.push({type: type, text: text})
  end
  
  # Accept a sort querystring in the format "category" or "-category", and
  # return a hash in the form [category: :category, direction: ":asc|:desc"].
  # Parameters:
  # +query+:                Sort querystring in the format "category" or
  #                         "-category"
  # +permitted_categories+: An array of category strings which the sort is
  #                         limited to. If no category is specified in the
  #                         query, or if the category provided is not in this
  #                         array, then the first element of this array will be
  #                         returned as the category.
  # +default_direction+:    Symbol for the direction to return if no direction
  #                         is specified
  def sort_parse(query, permitted_categories, default_direction)
    return {category: permitted_categories.first.to_sym, direction: default_direction} if query.nil?
    result = Hash.new
    # Extract category and direction
    if query[0] == "-"
      category = query[1..-1]
      result[:direction] = :desc
    else
      category = query
      result[:direction] = :asc
    end
    # Check if category is in the query:
    if permitted_categories.include?(category)
      result[:category] = category.to_sym
    else
      result[:category] = permitted_categories.first.to_sym
      result[:direction] = default_direction
    end
    return result
  end
  
  def superlatives(flights)
    # This function takes a collection of flights and returns a superlatives collection.
    route_distances = Hash.new()
    route_hash = Hash.new()
    Route.find_by_sql("SELECT routes.distance_mi, airports1.iata_code AS iata1, airports2.iata_code AS iata2 FROM routes JOIN airports AS airports1 ON airports1.id = routes.airport1_id JOIN airports AS airports2 ON airports2.id = routes.airport2_id").map{|x| route_hash[[x.iata1,x.iata2]] = x.distance_mi }
    flights.each do |flight|
      airport_alphabetize = [flight.origin_airport.iata_code,flight.destination_airport.iata_code].sort
      route_distances[[airport_alphabetize[0],airport_alphabetize[1]]] = route_hash[[airport_alphabetize[0],airport_alphabetize[1]]] || route_hash[[airport_alphabetize[1],airport_alphabetize[0]]] || -1
    end
    return superlatives_collection(route_distances)
    
  end
  
  def superlatives_collection(route_distances)
    # accept a hash of distances in format distances[[airport1,airport2]] = distance and return a hash of hashes of superlative distances
    return false if route_distances.length == 0
    route_max = route_distances.max_by{|k,v| v}[1]
    route_non_zero = route_distances.select{|k,v| v > 0}
    route_min = route_non_zero.length > 0 ? route_non_zero.min_by{|k,v| v}[1] : route_max
    route_superlatives = Hash.new
    route_superlatives[:max] = route_distances.select{|k,v| v == route_max}
    route_superlatives[:min] = route_distances.select{|k,v| v == route_min}
    route_superlatives[:zero] = route_distances.select{|k,v| v == 0}
    return route_superlatives
  end
  
  # Given a collection of Flights, returns their total distance.
  def total_distance(flights)
    
    # Get set of airports used in flights and select all routes with at least one of those airports
    used_airport_ids = Set.new
    flights.each do |flight|
      used_airport_ids << flight.origin_airport_id
      used_airport_ids << flight.destination_airport_id
    end
    route_envelope = Route.where("airport1_id IN (?) OR airport2_id IN (?)", used_airport_ids, used_airport_ids)
    
    # Sort airports numerically and create hash of airport distances
    distances = Hash.new(0)
    route_envelope.each do |route|
      airport_id = Array.new
      airport_id[0] = route.airport1_id
      airport_id[1] = route.airport2_id
      airport_id.sort!
      distances[airport_id] = route.distance_mi
    end
    
    # Loop through flights and sum distances
    total_distance = 0
    flights.each do |flight|
      airport_id = Array.new
      airport_id[0] = flight.origin_airport_id
      airport_id[1] = flight.destination_airport_id
      airport_id.sort!
      total_distance += distances[airport_id]
    end
    
    return total_distance
    
  end
  
  def json_request?
    request.format.json?
  end
  
end
