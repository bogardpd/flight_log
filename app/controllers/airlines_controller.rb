# Controls {Airline} pages and actions, including {#show_operator operators}
# and {#show_fleet_number fleet numbers}.

class AirlinesController < ApplicationController
  before_action :logged_in_user, :only => [:new, :create, :edit, :update, :destroy]
  
  # Shows a table of all {Airline Airlines} flown.
  #
  # @return [nil]
  def index
    @logo_used = true
    add_breadcrumb "Airlines", airlines_path
    add_admin_action view_context.link_to("Add New Airline", new_airline_path)
    
    @flights = flyer.flights(current_user)
    @sort = Table.sort_parse(params[:sort], :flights, :desc)
    @airlines  = Airline.flight_table_data(@flights, *@sort, type: :airline)
    @operators = Airline.flight_table_data(@flights, *@sort, type: :operator)
        
    used_airline_ids = (@airlines + @operators).map{|a| a[:id]}.uniq.compact
    @airlines_with_no_flights = Airline.where("id NOT IN (?)", used_airline_ids).order(:airline_name) if logged_in?
    
    if (@airlines.any? || @operators.any?)
      
      # Find maxima for graph scaling:
      @airlines_maximum  = @airlines.any?  ?  @airlines.max_by{|i| i[:flight_count]}[:flight_count] : 0
      @operators_maximum = @operators.any? ? @operators.max_by{|i| i[:flight_count]}[:flight_count] : 0
    
    end
     
  end
  
  # Shows details for a particular {Airline} and data for all {Flight Flights}
  # flown under its brand.
  # 
  # {Airline} details:
  # * name
  # * logo
  # * IATA and ICAO codes
  # 
  # {Flight} data:
  # * a {FlightsMap}
  # * a table of {Flight Flights}
  # * the total distance flown
  # * a table of {#show_operator operators}
  # * a table of {AircraftFamily AircraftFamilies}
  # * a table of {FlightsController#show_class classes}
  # * the longest and shortest {Flight}
  #
  # @return [nil]
  def show
    @airline = Airline.where(:iata_airline_code => params[:id]).first
    raise ActiveRecord::RecordNotFound if (@airline.nil?)
    
    @flights = flyer.flights(current_user).where(airline_id: @airline.id).includes(:airline, :origin_airport, :destination_airport, :trip)
    raise ActiveRecord::RecordNotFound if (!logged_in? && @flights.length == 0)
    
    @logo_used = true
    @region = current_region(default: [])
    
    add_breadcrumb "Airlines", airlines_path
    add_breadcrumb @title, airline_path(@airline.iata_airline_code)
    
    add_admin_action view_context.link_to("Delete Airline", @airline, method: :delete, data: {:confirm => "Are you sure you want to delete #{@airline.airline_name}?"}, class: "warning") if @flights.length == 0
    add_admin_action view_context.link_to("Edit Airline", edit_airline_path(@airline))
    
    # Create map:
    @map = FlightsMap.new(@flights, region: @region)
    
    # Calculate total flight distance:
    @total_distance = Route.total_distance(@flights)
    
    # Create comparitive lists of aircraft and classes:
    @airlines = Airline.flight_table_data(@flights, type: :airline) # Not used for an airline table, but needed so that the operator table can tell whether all flights are on the advertised airline.
    @operators = Airline.flight_table_data(@flights, type: :operator)
    @aircraft_families = AircraftFamily.flight_table_data(@flights)
    @classes = TravelClass.flight_table_data(@flights)
    
    # Create superlatives:
    @route_superlatives = superlatives(@flights)
    
    rescue ActiveRecord::RecordNotFound
      flash[:warning] = "We couldnʼt find an airline with an IATA code of #{params[:id]}. Instead, weʼll give you a list of airlines."
      redirect_to airlines_path
      
  end
  
  # Shows details for a particular operator (the {Airline} which actually
  # operates a flight, which may or may not be the same as the {Airline} which
  # brands the flight) and data for all {Flight Flights} operated by it.
  # 
  # Operator ({Airline}) details:
  # * name
  # * logo
  # * IATA and ICAO codes
  # 
  # {Flight} data:
  # * a {FlightsMap}
  # * a table of {Flight Flights}
  # * the total distance flown
  # * a table of {Airline Airlines} administrating these {Flight Flights}
  # * a table of {AircraftFamily AircraftFamilies}
  # * a table of {FlightsController#show_class classes}
  # * a table of {#show_fleet_number fleet numbers}
  # * the longest and shortest {Flight}
  #
  # @return [nil]
  def show_operator
    @operator = Airline.where(:iata_airline_code => params[:operator]).first
    raise ActiveRecord::RecordNotFound if (@operator.nil?)
    
    @flights = flyer.flights(current_user).where(operator_id: @operator.id).includes(:airline, :aircraft_family, :origin_airport, :destination_airport, :trip)
    raise ActiveRecord::RecordNotFound if (!logged_in? && @flights.length == 0)
 
    @logo_used = true
    @region = current_region(default: [])
    
    add_breadcrumb "Airlines", airlines_path
    add_breadcrumb "Flights Operated by " + @operator.airline_name, show_operator_path(@operator.iata_airline_code)
    
    add_admin_action view_context.link_to("Delete Airline", @operator, method: :delete, data: {:confirm => "Are you sure you want to delete #{@operator.airline_name}?"}, class: "warning") if @flights.length == 0
    add_admin_action view_context.link_to("Edit Airline", edit_airline_path(@operator))
    
    @total_distance = Route.total_distance(@flights)
    @map = FlightsMap.new(@flights, region: @region)
    
    # Create comparitive lists of airlines, aircraft and classes:
    @airlines = Airline.flight_table_data(@flights, type: :airline)
    @aircraft_families = AircraftFamily.flight_table_data(@flights)
    @classes = TravelClass.flight_table_data(@flights)
    
    # Create superlatives:
    @route_superlatives = superlatives(@flights)
    
    # Create list of fleet numbers and aircraft families:
    @fleet_family = Hash.new
    @fleet_name = Hash.new
    @flights.each do |flight|
      if flight.fleet_number
        @fleet_family[flight.fleet_number] = flight.aircraft_family.family_name
        @fleet_name[flight.fleet_number] = flight.aircraft_name
      end
    end
    @fleet_family = @fleet_family.sort_by{ |key, value| key }
        
  rescue ActiveRecord::RecordNotFound
    flash[:warning] = "We couldnʼt find any flights operated by #{params[:operator]}. Instead, weʼll give you a list of airlines and operators."
    redirect_to airlines_path
  end
  
  # Shows data for all {Flight Flights} associated with a particular
  # {#show_operator operator} and fleet number combination.
  #
  # {Flight} data:
  # * a {FlightsMap}
  # * a table of {Flight Flights} (including the {AircraftFamily} and {FlightsController#show_tail tail number} of each {Flight})
  # * the total distance flown
  # * a table of {Airline Airlines} administrating these {Flight Flights}
  # * a table of {AircraftFamily AircraftFamilies}
  # * a table of {FlightsController#show_class classes}
  # * the longest and shortest {Flight}
  #
  # @return [nil]
  def show_fleet_number
    @operator = Airline.where(:iata_airline_code => params[:operator]).first
    @fleet_number = params[:fleet_number]
    
    @flights = flyer.flights(current_user).where(operator_id: @operator.id, fleet_number: @fleet_number).includes(:airline, :origin_airport, :destination_airport, :trip)
    raise ActiveRecord::RecordNotFound if @flights.length == 0
    
    @logo_used = true
    @region = current_region(default: [])
    add_breadcrumb "Airlines", airlines_path
    add_breadcrumb "Flights Operated by #{@operator.airline_name}", show_operator_path(@operator.iata_airline_code)
    add_breadcrumb "#" + @fleet_number, show_fleet_number_path(@operator.iata_airline_code, @fleet_number)
    
    @total_distance = Route.total_distance(@flights)
    @map = FlightsMap.new(@flights, region: @region)
    
    # Create comparitive lists of airlines, aircraft and classes:
    @airlines = Airline.flight_table_data(@flights, type: :airline)
    @aircraft_families = AircraftFamily.flight_table_data(@flights)
    @classes = TravelClass.flight_table_data(@flights)
    
    # Create superlatives:
    @route_superlatives = superlatives(@flights)
    
  rescue ActiveRecord::RecordNotFound
    flash[:warning] = "We couldnʼt find any flights operated by #{@operator} with fleet number ##{@fleet_number}. Instead, weʼll give you a list of airlines and operators."
    redirect_to airlines_path
  end
  
  # Shows a form to add an {Airline}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def new
    session[:form_location] = nil
    add_breadcrumb "Airlines", airlines_path
    add_breadcrumb "New Airline", new_airline_path
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
      flash[:success] = "Successfully added #{params[:airline][:airline_name]}!"
      if session[:form_location]
        form_location = session[:form_location]
        session[:form_location] = nil
        redirect_to form_location
      else
        if @airline.is_only_operator
          redirect_to show_operator_path(@airline.iata_airline_code)
        else
          redirect_to airline_path(@airline.iata_airline_code)
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
    add_breadcrumb "Airlines", airlines_path
    add_breadcrumb @airline.airline_name, airline_path(@airline.iata_airline_code)
    add_breadcrumb "Edit Airline", edit_airport_path(@airline)
  end
  
  # Updates an existing {Airline}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def update
    @airline = Airline.find(params[:id])
    if @airline.update_attributes(airline_params)
      flash[:success] = "Successfully updated airline."
      if @airline.is_only_operator
        redirect_to show_operator_path(@airline.iata_airline_code)
      else
        redirect_to airline_path(@airline.iata_airline_code)
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
    if @airline.flights.any?
      flash[:error] = "This airline still has flights and could not be deleted. Please delete all of this airlineʼs flights first."
      redirect_to airline_path(params[:id])
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
    params.require(:airline).permit(:iata_airline_code, :icao_airline_code, :airline_name, :numeric_code, :is_only_operator)
  end
  
end