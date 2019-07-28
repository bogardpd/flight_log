# Controls pages which don't fall under a specific model.
class PagesController < ApplicationController

  # Shows the front page for Flight Historian, including summaries of all {Flight Flights}.
  #
  # Includes:
  # * a {FlightsMap}
  # * the top 5 {Airport Airports}, {Airline Airlines}, {Route Routes}, {AircraftFamily AircraftFamilies}, and {TailNumber TailNumbers}
  # * the longest and shortest {Flight}
  #
  # @return [nil]
  def flightlog
    @logo_used = true
    @region = current_region(default: [])
    
    @flights = flyer.flights(current_user).includes(:origin_airport, :destination_airport)
    
    @flight_aircraft = AircraftFamily.flight_table_data(@flights)
    @flight_airlines = Airline.flight_table_data(@flights, type: :airline)
    @flight_airports = Airport.visit_table_data(@flights)
    @flight_routes = Route.flight_table_data(@flights)
    @flight_tails = TailNumber.flight_table_data(@flights)
    
    if logged_in?
      Trip.where(hidden: true).map{|trip| add_message(:info, "Active Trip: #{view_context.link_to(trip.name, trip_path(trip), class: "title")}")} # Link to hidden trips
      add_message(:info, "You have boarding passes you can #{view_context.link_to("import", new_flight_menu_path)}!") if PKPass.any?
      if @flight_routes.find{|x| x[:distance_mi] < 0}
        add_message(:warning, "Some #{view_context.link_to("routes", routes_path)} don’t have distances.")
      end
    end
    
    @total_distance = Route.total_distance(@flights)    
    
    if @flights.any?
      @map = FlightsMap.new(@flights, region: @region)
      @route_superlatives = superlatives(@flights)
    end

  end
  
  # Responds to a Let's Encrypt query. Used to renew SSL certificates.
  #
  # @return [nil]
  # @see https://letsencrypt.org Let's Encrypt
  def letsencrypt
    render text: ENV["LETS_ENCRYPT_KEY"]
  end
  
  # Takes a {http://www.gcmap.com/ Great Circle Mapper} map
  # image and serves it from the Flight Historian server. This is needed
  # because the Great Circle Mapper is HTTP only while Flight Historian is
  # HTTPS, and browsers will give certificate errors if an HTTP image is
  # embedded in an HTTPS page.
  # 
  # In order to prevent other sites from using this proxy, this method will
  # only render an image if the parameters include a valid checksum generated
  # by {Map.hash_image_query}, and will otherwise return a Not Found error.
  #
  # @return [nil]
  # @see Map.hash_image_query
  # @see http://www.gcmap.com/ Great Circle Mapper
  def gcmap_image_proxy
    require "open-uri"
    
    query = params[:query].gsub("_","/")
    
    if Map.hash_image_query(query) == params[:check] # Ensure the query was issued by this application
      response.headers["Cache-Control"] = "public, max-age=#{84.hours.to_i}"
      response.headers["Content-Type"] = "image/gif"
      response.headers["Content-Disposition"] = "inline"
      image_url = "http://www.gcmap.com/map?PM=#{params[:airport_options]}&MP=r&MS=wls2&P=#{query}"
      render body: open(image_url, "rb").read
    else
      raise ActionController::RoutingError.new("Not Found")
    end
    
  rescue SocketError
  end

end