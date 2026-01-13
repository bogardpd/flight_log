# Controls pages which don't fall under a specific model.
class PagesController < ApplicationController
  before_action :logged_in_user, except: [:letsencrypt]

  # Shows the front page for Flight Historian, including summaries of all {Flight Flights}.
  #
  # @return [nil]
  def flightlog
    @logo_used = true

    @flights = flyer.flights(current_user)

    @flight_aircraft = AircraftFamily.flight_table_data(@flights).reject{|aircraft| aircraft[:id].nil?}
    @flight_airlines = Airline.flight_table_data(@flights, type: :airline).reject{|airline| airline[:id].nil?}
    @flight_airports = Airport.visit_table_data(@flights)
    @flight_routes = Route.flight_table_data(@flights)
    @flight_tails = TailNumber.flight_table_data(@flights)

    if logged_in?
      Trip.where(hidden: true).map{|trip| add_message(:info, "Active Trip: #{view_context.link_to(trip.name, trip_path(trip), class: "title")}", "message-active-trip-#{trip.id}")} # Link to hidden trips
      add_message(:info, "You have boarding passes you can #{view_context.link_to("import", new_flight_menu_path)}!", "message-boarding-passes-available-for-import") if PKPass.any?
      if @flight_routes.find{|x| x[:distance_mi].nil?}
        add_message(:warning, "Some #{view_context.link_to("routes", routes_path)} don’t have distances.")
      end
    end

    @total_distance = @flights.total_distance

    if @flights.any?
      @maps = {
        flights_map: FlightsMap.new(:flights_map, @flights),
      }
      render_map_extension(@maps, params[:map_id], params[:extension])
      @route_superlatives = @flights.superlatives
    end

  end

  # Responds to a Let's Encrypt query. Used to renew SSL certificates.
  #
  # @return [nil]
  # @see https://letsencrypt.org Let's Encrypt
  def letsencrypt
    render plain: ENV["LETS_ENCRYPT_KEY"]
  end

end