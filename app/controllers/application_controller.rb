# Provides controller methods for the entire application.
class ApplicationController < ActionController::Base
  protect_from_forgery
  
  include SessionsHelper
  
  # Returns an array of region ICAO code prefixes (e.g. ["K","PH"]) based on
  # the region parameter in the URL if present, and the default if absent.
  #
  # @param default [Array<String>] a set of region ICAO code prefixes to use
  #   if params does not contain a region.
  # @return [Array<String>] the parameter region if present, otherwise the
  #   provided default region
  def current_region(default: [])
    return default unless params[:region]
    icao_starts = params[:region].split(/[\-,]/)
    icao_starts.compact!
    icao_starts.uniq!
    icao_starts.map!{|s| s.upcase.tr("^A-Z","")}
    return icao_starts
  end
  
  # Returns the {User} whose flights are being viewed. Until multiple user
  # functionality is added to Flight Historian, this will simply return the
  # first user.
  #
  # @return [User] the {User} whose flights are being viewed
  def flyer
    return User.first
  end
  helper_method :flyer
  
  # Redirects to the root page unless the user is logged in.
  #
  # @return [nil]
  def logged_in_user
    unless logged_in?
      redirect_to root_url
    end
  end
  
  # Gets attachments from boarding pass emails.
  #
  # @return [nil]
  def check_email_for_boarding_passes
    begin
      BoardingPassEmail::process_attachments(current_user.all_emails)
    rescue => details
      flash.now[:warning] = "Could not get new passes from email (#{details})"
    end
  end

  # Adds a navigation breadcrumb.
  #
  # @param text [String] the link's text
  # @param path [Rails::Paths::Path] the link's path
  # @return [nil]
  def add_breadcrumb(text, path)
    @breadcrumbs ||= [["Home", root_path]]
    @breadcrumbs.push([text, path])
  end

  # Adds a link to the admin block.
  #
  # @param link [ActiveSupport::SafeBuffer] a link_to object
  # @return [nil]
  def add_admin_action(link)
    @admin_actions ||= Array.new
    @admin_actions.push(link)
  end
  
  # Adds a message to the alert messages box at the top of the page.
  #
  # @param type [:info, :success, :warning, :error] the type of message to
  #   display. Used to determine the color of the message box.
  # @param text [String] the message text
  # @return [nil]
  def add_message(type, text)
    @messages ||= []
    @messages.push({type: type, text: text})
  end
  
  # Accept a sort querystring in the format "category" or "-category", and
  # return a hash of sort category and direction.
  # 
  # @param query [String] a sort querystring in the format "category" or
  #   "-category"
  # @param default_category [Symbol] the sort category to return if no category
  #   is specified
  # @param default_direction [:asc, :desc] the sort direction to return if no
  #   direction is specified
  # @return [Array<Symbol>] an array containing a symbol for sort category and
  #   a symbol for sort direction
  def sort_parse(query, default_category, default_direction)
    return [default_category, default_direction] if query.nil?
    
    # Extract category and direction
    if query[0] == "-"
      category = query[1..-1].to_sym
      direction = :desc
    else
      category = query.to_sym
      direction = :asc
    end
    
    return [category, direction]
  end
  
  # Return the longest and shortest flights from a collection of flights. 
  # 
  # If multiple flights tie for longest or shortest (have the same distance),
  # then an array will be returned containing all tied flights. If the longest
  # or shortest are not tied, then an array will still be returned, with only
  # one element.
  # 
  # If any of the included flights have zero distance (they departed from and
  # arrived at the same airport), the shortest non-zero-distance flight is
  # considered the shortest flight, and all zero-length flights are returned in
  # an array.
  #
  # @param flights [Array<Flight>] a collection of {Flight Flights}
  # @return [Hash<Symbol, Hash>] a hash of the longest, shortest (non-zero), and zero
  #   length flights (distances in statute miles)
  # @example superlatives(Flight.all) #=> {:max => [{[Airport1,Airport2] => 8500}],
  #   :min => [{[Airport3,Airport4] => 50},{[Airport5,Airport6] => 50}], [:zero =>
  #   {[Airport7,Airport7] => 0}]}
  def superlatives(flights)
    route_distances = Hash.new()
    route_hash = Hash.new()
    Route.find_by_sql("SELECT routes.distance_mi, airports1.iata_code AS iata1, airports2.iata_code AS iata2 FROM routes JOIN airports AS airports1 ON airports1.id = routes.airport1_id JOIN airports AS airports2 ON airports2.id = routes.airport2_id").map{|x| route_hash[[x.iata1,x.iata2]] = x.distance_mi }
    flights.each do |flight|
      airport_alphabetize = [flight.origin_airport.iata_code,flight.destination_airport.iata_code].sort
      route_distances[[airport_alphabetize[0],airport_alphabetize[1]]] = route_hash[[airport_alphabetize[0],airport_alphabetize[1]]] || route_hash[[airport_alphabetize[1],airport_alphabetize[0]]] || -1
    end
    return superlatives_collection(route_distances)
    
  end
  
  # Accept a hash of distances, and return a hash superlative distances. The
  # return hash is in the same format as {#superlatives}.
  #
  # @param route_distances [Hash<Array, Number>] a hash in the format
  #   [{Airport},{Airport}] => distance, where distance is in statute miles
  # @return [Hash<Symbol, Hash>] a hash of the longest, shortest (non-zero), and zero
  #   length flights (distances in statute miles)
  # @see #superlatives
  def superlatives_collection(route_distances)
    
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
  
end
