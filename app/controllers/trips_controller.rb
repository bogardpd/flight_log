# Controls {Trip} pages and actions, including {#show_section trip sections}.
class TripsController < ApplicationController
  before_action :logged_in_user, :only => [:new, :create, :edit, :update, :destroy]
  
  # Shows a table of all {Trip Trips} flown.
  #
  # @return [nil]
  def index
    @sort = Table.sort_parse(params[:sort], :departure, :desc)
    @trips = Trip.with_departure_dates(flyer, current_user, *@sort)
    @trips_with_no_flights = Trip.with_no_flights
  end

  # Shows details for a particular {Trip} and its {Flight Flights}.
  # 
  # {Trip} details:
  # * comments
  # 
  # {Flight} data:
  # * a {FlightsMap}
  # * a table of {Flight Flights}, separated by {#show_section trip section}
  # * the total distance flown
  #
  # @return [nil]
  def show
    @logo_used = true
    @trip = Trip.find(params[:id])
    raise ActiveRecord::RecordNotFound if (flyer != current_user && @trip.hidden)
    @flights = Flight.where(trip_id: @trip)
        
    add_message(:warning, "This trip is hidden!") if @trip.hidden

    if logged_in? && @trip.hidden
      check_email_for_boarding_passes
      add_message(:info, "You have boarding passes you can #{view_context.link_to("import", new_flight_menu_path(trip_id: @trip))}!", "message-boarding-passes-available-for-import") if PKPass.all.any?
    end
    
    @trip_distance = @flights.total_distance
    @sections_and_flights = @trip.sections_and_flights

    stops = @sections_and_flights.map{|k, v| [v.first.origin_airport,v.last.destination_airport]}.flatten.uniq
    
    # Create map
    @map = FlightsMap.new(:trip_map, @flights, highlighted_airports: stops, include_names: true)

  rescue ActiveRecord::RecordNotFound
    flash[:warning] = "We couldnʼt find a trip with an ID of #{params[:id]}. Instead, weʼll give you a list of trips."
    redirect_to trips_path
  end
  
  # Shows flight data for a particular section of a {Trip}.
  #
  # Trip sections are used to distinguish between layovers and multiple visits
  # to a given airport within a given {Trip}, in the situation where two
  # flights are chronologically consecutive and the destination {Airport} of
  # the first flight is the same as the origin of the second. If these two
  # flights share the same {Trip} and trip section, then the time between the
  # two flights is a layover and only counts as one visit to shared {Airport}.
  # Otherwise, the traveler left the airport in between the flights, and it
  # counts as two separate visits to the shared {Airport}.
  # 
  # {Flight} data:
  # * a {FlightsMap}
  # * a table of {Flight Flights}
  # * the total distance flown
  # * the layover ratio (the total distance flown divided by the distance
  #   between the first origin and final destination {Airport Airports}), if
  #   this section has more than one flight.
  #
  # @return [nil]
  def show_section
    @logo_used = true
    @trip = Trip.find(params[:trip])
    @section = params[:section]
    
    raise ActiveRecord::RecordNotFound if (flyer != current_user && @trip.hidden)
    
    add_message(:warning, "This trip is hidden!") if @trip.hidden
    
    @flights = Flight.where(trip_id: @trip, trip_section: @section).includes(:airline, :origin_airport, :destination_airport, :trip).order(:departure_utc)
    raise ActiveRecord::RecordNotFound unless @flights.any?

    @section_distance = @flights.total_distance
    layover_ratio = @trip.layover_ratio(@section)
    stops = [@flights.first.origin_airport,@flights.last.destination_airport]
    
    @map = FlightsMap.new(:trip_section_map, @flights, highlighted_airports: stops, include_names: true)

    @summary_items = Hash.new
    @summary_items.store("Trip", view_context.link_to(@trip.name, trip_path(@trip)))
    if @flights.size > 1 && layover_ratio
      @summary_items.store("Layover Ratio", view_context.link_to(layover_ratio.round(3), "https://onehundredairports.com/2019/02/07/my-worst-layovers/", target: :_blank))
    end
    
  rescue ActiveRecord::RecordNotFound
    flash[:warning] = "We couldnʼt find a matching trip section. Instead, weʼll give you a list of trips."
    redirect_to trips_path
  end
  
  # Shows a form to add a {Trip}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def new
    @trip = Trip.new(hidden: true)
  end
  
  # Creates a new {Trip}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def create
    @trip = current_user.trips.new(trip_params)
    if @trip.save
      flash[:success] = "Successfully added #{params[:trip][:name]}!"
      redirect_to @trip
    else
      render "new"
    end
  end
  
  # Shows a form to edit an existing {Trip}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def edit
    @trip = Trip.find(params[:id])
  end
  
  # Updates an existing {Trip}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def update
    @trip = Trip.find(params[:id])
    if @trip.update(trip_params)
      flash[:success] = "Successfully updated trip."
      redirect_to @trip
    else
      render "edit"
    end
  end
  
  # Deletes an existing {Trip}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def destroy
    @flights = Flight.where("trip_id = :trip_id", {:trip_id => params[:id]})
    if @flights.any?
      flash[:error] = "This trip still has flights and could not be deleted. Please delete all of this tripʼs flights first."
      redirect_to trip_path(params[:id])
    else
      Trip.find(params[:id]).destroy
      flash[:success] = "Trip destroyed."
      redirect_to trips_path
    end
  end
  
  private
  
  # Defines permitted {Airline} parameters.
  #
  # @return [ActionController::Parameters]
  def trip_params
    params.require(:trip).permit(:comment, :hidden, :name, :purpose)
  end
    
end
