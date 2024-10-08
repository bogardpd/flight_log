# Controls {Airline} pages and actions, including {#show_operator operators}
# and {#show_fleet_number fleet numbers}.

class AirlinesController < ApplicationController
  before_action :logged_in_user, :only => [:new, :create, :edit, :update, :destroy]
  
  # Shows a table of all {Airline Airlines} flown.
  #
  # @return [nil]
  def index
    @logo_used = true
    
    @flights = flyer.flights(current_user)
    @sort = Table.sort_parse(params[:sort], :flights, :desc)
    @airlines  = Airline.flight_table_data(@flights, *@sort, type: :airline)
    @operators = Airline.flight_table_data(@flights, *@sort, type: :operator)
        
    used_airline_ids = (@airlines + @operators).map{|a| a[:id]}.uniq.compact
    @airlines_with_no_flights = Airline.where("id NOT IN (?)", used_airline_ids).order(:name) if logged_in?
    
    if (@airlines.any? || @operators.any?)
      
      # Find maxima for graph scaling:
      @airlines_maximum  = @airlines.any?  ?  @airlines.max_by{|i| i[:flight_count]}[:flight_count] : 0
      @operators_maximum = @operators.any? ? @operators.max_by{|i| i[:flight_count]}[:flight_count] : 0
    
    end
     
  end
  
  # Shows details for a particular {Airline} and data for all {Flight Flights}
  # flown under its brand.
  #
  # @return [nil]
  def show
    @airline = Airline.find_by(slug: params[:id])
    raise ActiveRecord::RecordNotFound if (@airline.nil?)
    
    @flights = flyer.flights(current_user).where(airline_id: @airline.id).includes(:airline, :origin_airport, :destination_airport, :trip)
    raise ActiveRecord::RecordNotFound if (!logged_in? && @flights.length == 0)
    @logo_used = true
    
    # Create map:
    @maps = {
      airline_map: FlightsMap.new(:airline_map, @flights),
    }
    render_map_extension(@maps, params[:map_id], params[:extension])
    
    # Calculate total flight distance:
    @total_distance = @flights.total_distance
    
    # Create comparitive lists of aircraft and classes:
    @airlines = Airline.flight_table_data(@flights, type: :airline) # Not used for an airline table, but needed so that the operator table can tell whether all flights are on the advertised airline.
    @operators = Airline.flight_table_data(@flights, type: :operator)
    @aircraft_families = AircraftFamily.flight_table_data(@flights)
    @classes = TravelClass.flight_table_data(@flights)
    
    # Create superlatives:
    @route_superlatives = @flights.superlatives
    
  rescue ActiveRecord::RecordNotFound
    flash[:warning] = %Q(We couldnʼt find an airline matching <span class="param-highlight">#{params[:id]}</span>. Instead, weʼll give you a list of airlines.)
    redirect_to airlines_path
      
  end
  
  # Shows details for a particular operator (the {Airline} which actually
  # operates a flight, which may or may not be the same as the {Airline} which
  # brands the flight) and data for all {Flight Flights} operated by it.
  # 
  # @return [nil]
  def show_operator
    @operator = Airline.find_by(slug: params[:operator])
    raise ActiveRecord::RecordNotFound if (@operator.nil?)
    
    @flights = flyer.flights(current_user).where(operator_id: @operator.id).includes(:airline, :aircraft_family, :origin_airport, :destination_airport, :trip)
    raise ActiveRecord::RecordNotFound if (!logged_in? && @flights.length == 0)
 
    @logo_used = true

    @total_distance = @flights.total_distance
    @maps = {
      operator_map: FlightsMap.new(:operator_map, @flights),
    }
    render_map_extension(@maps, params[:map_id], params[:extension])
    
    # Create comparitive lists of airlines, aircraft and classes:
    @airlines = Airline.flight_table_data(@flights, type: :airline)
    @aircraft_families = AircraftFamily.flight_table_data(@flights)
    @classes = TravelClass.flight_table_data(@flights)
    
    # Create superlatives:
    @route_superlatives = @flights.superlatives
    
    # Create list of fleet numbers and aircraft families:
    @fleet = Hash.new
    @flights.each do |flight|
      if flight.fleet_number
        @fleet[flight.fleet_number] = Hash.new
        @fleet[flight.fleet_number].store(:aircraft, flight.aircraft_family.full_name)
        @fleet[flight.fleet_number].store(:aircraft_icao, flight.aircraft_family.icao_code)
        @fleet[flight.fleet_number].store(:name, flight.aircraft_name)
        @fleet[flight.fleet_number].store(:tail, flight.tail_number)
      end
    end
    @fleet = @fleet.sort_by{ |key, value| key }
        
  rescue ActiveRecord::RecordNotFound
    flash[:warning] = %Q(We couldnʼt find any flights operated by <span class="param-highlight">#{params[:operator]}</span>. Instead, weʼll give you a list of airlines and operators.)
    redirect_to airlines_path
  end
  
  # Shows data for all {Flight Flights} associated with a particular
  # {#show_operator operator} and fleet number combination.
  #
  # @return [nil]
  def show_fleet_number
    @operator = Airline.find_by(slug: params[:operator])
    raise ActiveRecord::RecordNotFound if (@operator.nil?)
    
    @fleet_number = params[:fleet_number]
    @flights = flyer.flights(current_user).where(operator_id: @operator.id, fleet_number: @fleet_number).includes(:airline, :origin_airport, :destination_airport, :trip)
    raise ActiveRecord::RecordNotFound if @flights.length == 0
    
    @logo_used = true
    
    @total_distance = @flights.total_distance
    @maps = {
      fleet_number_map: FlightsMap.new(:fleet_number_map, @flights),
    }
    render_map_extension(@maps, params[:map_id], params[:extension])
    
    # Create comparitive lists of airlines, aircraft and classes:
    @airlines = Airline.flight_table_data(@flights, type: :airline)
    @aircraft_families = AircraftFamily.flight_table_data(@flights)
    @classes = TravelClass.flight_table_data(@flights)
    
    # Create superlatives:
    @route_superlatives = @flights.superlatives
    
  rescue ActiveRecord::RecordNotFound
    flash[:warning] = %Q(We couldnʼt find any flights operated by <span class="param-highlight">#{params[:operator]}</span> with fleet number #<span class="param-highlight">#{params[:fleet_number]}</span>. Instead, weʼll give you a list of airlines and operators.)
    redirect_to airlines_path
  end
  
  # Shows a form to add an {Airline}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def new
    session[:form_location] = nil
    @airline = Airline.new
  end
  
  # Creates a new {Airline}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def create
    @airline = Airline.new(airline_params)
    if @airline.save
      flash[:success] = "Successfully added #{params[:airline][:name]}!"
      if session[:form_location]
        form_location = session[:form_location]
        session[:form_location] = nil
        redirect_to form_location
      else
        if @airline.is_only_operator
          redirect_to show_operator_path(@airline.slug)
        else
          redirect_to airline_path(@airline.slug)
        end
      end
    else
      if session[:form_location]
        render "flights/new_undefined_airline"
      else
        render "new"
      end
    end
  end
  
  # Shows a form to edit an existing {Airline}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def edit
    session[:form_location] = nil
    @airline = Airline.find(params[:id])
  end
  
  # Updates an existing {Airline}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def update
    @airline = Airline.find(params[:id])
    if @airline.update(airline_params)
      flash[:success] = "Successfully updated airline."
      if @airline.is_only_operator
        redirect_to show_operator_path(@airline.slug)
      else
        redirect_to airline_path(@airline.slug)
      end
    else
      render "edit"
    end
  end
  
  # Deletes an existing {Airline}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def destroy
    @airline = Airline.find(params[:id])
    if @airline.has_any_airline_operator_codeshare_flights?
      flash[:error] = "This airline still has flights and could not be deleted. Please delete all of this airlineʼs flights first."
      redirect_to airline_path(@airline.slug)
    else
      @airline.destroy
      flash[:success] = "Airline deleted."
      redirect_to airlines_path
    end
  end
  
  private
  
  # Defines permitted {Airline} parameters.
  #
  # @return [ActionController::Parameters]
  def airline_params
    params.require(:airline).permit(:name, :slug, :iata_code, :icao_code, :numeric_code, :is_only_operator)
  end
  
end