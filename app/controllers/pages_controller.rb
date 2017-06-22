# encoding: UTF-8

class PagesController < ApplicationController

  def flightlog
    # Flight Log Index
    @meta_description = "Paul Bogardʼs Flight Historian shows maps and tables for various breakdowns of Paulʼs flight history."
    @logo_used = true
    @region = current_region(default: :conus)
    
    @flight_aircraft = AircraftFamily.flight_count(logged_in?)
    @flight_airlines = Airline.flight_count(logged_in?, type: :airline)
    @flight_airports = Airport.visit_count(logged_in?)
    @flight_routes = Route.flight_count(logged_in?)
    @flight_tails = TailNumber.flight_count(logged_in?)
    
    if logged_in?
      @flights = Flight.flights_table
      Trip.where(hidden: true).map{|trip| add_message(:info, "Active Trip: #{view_context.link_to(trip.name, trip_path(trip), class: "title")}")} # Link to hidden trips
      add_message(:info, "You have boarding passes you can #{view_context.link_to("import", import_boarding_passes_path)}!") if PKPass.any?
      if Route.flight_count(logged_in?).find{|x| x[:distance_mi] < 0}
        add_message(:warning, "Some #{view_context.link_to("routes", routes_path)} don’t have distances.")
      end
    else
      @flights = Flight.visitor.flights_table
    end
    
    @total_distance = total_distance(@flights)    
    
    if @flights.any?
      @map = FlightsMap.new(@flights, region: @region)
      @route_superlatives = superlatives(@flights)
    end

  end
  
  def letsencrypt
    render text: ENV["LETS_ENCRYPT_KEY"]
  end
  
  def gcmap_image_proxy
    require 'open-uri'
    
    query = params[:query].gsub('_','/')
    
    if Map.hash_image_query(query) == params[:check] # Ensure the query was issued by this application
      response.headers['Cache-Control'] = "public, max-age=#{84.hours.to_i}"
      response.headers['Content-Type'] = 'image/gif'
      response.headers['Content-Disposition'] = 'inline'
      image_url = "http://www.gcmap.com/map?PM=#{params[:airport_options]}&MP=r&MS=wls2&P=#{query}"
      render body: open(image_url, "rb").read
    else
      raise ActionController::RoutingError.new('Not Found')
    end
    
  rescue SocketError
  end

end