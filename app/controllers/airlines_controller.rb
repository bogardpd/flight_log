class AirlinesController < ApplicationController
  before_action :logged_in_user, :only => [:new, :create, :edit, :update, :destroy]
  add_breadcrumb "Home", "root_path"
  
  def index
    @logo_used = true
    @title = "Airlines"
    @meta_description = "A list of the airlines on which Paul Bogard has flown, and how often heʼs flown on each."
    add_breadcrumb "Airlines", "airlines_path"
    add_admin_action view_context.link_to("Add New Airline", new_airline_path)
    
    @flights = flyer.flights(current_user)
    @airlines  = Airline.flight_count(@flights, type: :airline)
    @operators = Airline.flight_count(@flights, type: :operator)
        
    used_airline_ids = (@airlines + @operators).map{|a| a[:id]}.uniq.compact
    @airlines_with_no_flights = Airline.where("id NOT IN (?)", used_airline_ids).order(:airline_name) if logged_in?
    
    
    if (@airlines.any? || @operators.any?)
      
      # Find maxima for graph scaling:
      @airlines_maximum  = @airlines.any?  ?  @airlines.max_by{|i| i[:flight_count]}[:flight_count] : 0
      @operators_maximum = @operators.any? ? @operators.max_by{|i| i[:flight_count]}[:flight_count] : 0
    
      # Sort airline and operator tables:
      sort_params = sort_parse(params[:sort], %w(flights airline code), :desc)
      @sort_cat   = sort_params[:category]
      @sort_dir   = sort_params[:direction]
      sort_mult   = (@sort_dir == :asc ? 1 : -1)
      
      case @sort_cat
      when :airline
        @airlines  =  @airlines.sort_by { |airline|   airline[:airline_name]&.downcase || "" }
        @operators = @operators.sort_by { |operator| operator[:airline_name]&.downcase || "" }
        @airlines.reverse!  if @sort_dir == :desc
        @operators.reverse! if @sort_dir == :desc
      when :code
        @airlines  =  @airlines.sort_by { |airline|   airline[:iata_airline_code]&.downcase || "" }
        @operators = @operators.sort_by { |operator| operator[:iata_airline_code]&.downcase || "" }
        @airlines.reverse!  if @sort_dir == :desc
        @operators.reverse! if @sort_dir == :desc
      when :flights
        @airlines  =  @airlines.sort_by { |airline|  [sort_mult * airline[:flight_count],  airline[:airline_name]&.downcase || ""] }
        @operators = @operators.sort_by { |operator| [sort_mult * operator[:flight_count], operator[:airline_name]&.downcase || ""] }
      end
    end
     
  end
  
  def show
    @airline = Airline.where(:iata_airline_code => params[:id]).first
    raise ActiveRecord::RecordNotFound if (@airline.nil?)
    
    @flights = flyer.flights(current_user).where(airline_id: @airline.id).includes(:airline, :origin_airport, :destination_airport, :trip)
    raise ActiveRecord::RecordNotFound if (!logged_in? && @flights.length == 0)
    
    @title = @airline.airline_name
    @meta_description = "Maps and lists of Paul Bogardʼs flights on #{@airline.airline_name}."
    @logo_used = true
    @region = current_region(default: [])
    
    add_breadcrumb "Airlines", "airlines_path"
    add_breadcrumb @title, "airline_path(@airline.iata_airline_code)"
    
    add_admin_action view_context.link_to("Delete Airline", @airline, method: :delete, data: {:confirm => "Are you sure you want to delete #{@airline.airline_name}?"}, class: "warning") if @flights.length == 0
    add_admin_action view_context.link_to("Edit Airline", edit_airline_path(@airline))
    
    # Create map:
    @map = FlightsMap.new(@flights, region: @region)
    
    # Calculate total flight distance:
    @total_distance = Route.total_distance(@flights)
    
    # Create comparitive lists of aircraft and classes:
    @airlines = Airline.flight_count(@flights, type: :airline) # Not used for an airline table, but needed so that the operator table can tell whether all flights are on the advertised airline.
    @operators = Airline.flight_count(@flights, type: :operator)
    @aircraft_families = AircraftFamily.flight_count(@flights)
    @classes = TravelClass.flight_count(@flights)
    
    # Create superlatives:
    @route_superlatives = superlatives(@flights)
    
    rescue ActiveRecord::RecordNotFound
      flash[:warning] = "We couldnʼt find an airline with an IATA code of #{params[:id]}. Instead, weʼll give you a list of airlines."
      redirect_to airlines_path
      
  end
  
  def show_operator
    @operator = Airline.where(:iata_airline_code => params[:operator]).first
    raise ActiveRecord::RecordNotFound if (@operator.nil?)
    
    @flights = flyer.flights(current_user).where(operator_id: @operator.id).includes(:airline, :aircraft_family, :origin_airport, :destination_airport, :trip)
    raise ActiveRecord::RecordNotFound if (!logged_in? && @flights.length == 0)
 
    @title = @operator.airline_name + " (Operator)"
    @meta_description = "Maps and lists of Paul Bogardʼs flights operated by #{@operator.airline_name}."
    @logo_used = true
    @region = current_region(default: [])
    
    add_breadcrumb "Airlines", "airlines_path"
    add_breadcrumb "Flights Operated by " + @operator.airline_name, show_operator_path(@operator.iata_airline_code)
    
    add_admin_action view_context.link_to("Delete Airline", @operator, method: :delete, data: {:confirm => "Are you sure you want to delete #{@operator.airline_name}?"}, class: "warning") if @flights.length == 0
    add_admin_action view_context.link_to("Edit Airline", edit_airline_path(@operator))
    
    @total_distance = Route.total_distance(@flights)
    @map = FlightsMap.new(@flights, region: @region)
    
    # Create comparitive lists of airlines, aircraft and classes:
    @airlines = Airline.flight_count(@flights, type: :airline)
    @aircraft_families = AircraftFamily.flight_count(@flights)
    @classes = TravelClass.flight_count(@flights)
    
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
  
  def show_fleet_number
    @operator = Airline.where(:iata_airline_code => params[:operator]).first
    @fleet_number = params[:fleet_number]
    
    @flights = flyer.flights(current_user).where(operator_id: @operator.id, fleet_number: @fleet_number).includes(:airline, :origin_airport, :destination_airport, :trip)
    raise ActiveRecord::RecordNotFound if @flights.length == 0
    
    @logo_used = true
    @region = current_region(default: [])
    @title = @operator.airline_name + " #" + @fleet_number
    @meta_description = "Maps and lists of Paul Bogardʼs flights operated on #{@operator.airline_name} ##{@fleet_number}."
    add_breadcrumb "Airlines", "airlines_path"
    add_breadcrumb "Flights Operated by #{@operator.airline_name}", show_operator_path(@operator.iata_airline_code)
    add_breadcrumb "#" + @fleet_number, show_fleet_number_path(@operator.iata_airline_code, @fleet_number)
    
    @total_distance = Route.total_distance(@flights)
    @map = FlightsMap.new(@flights, region: @region)
    
    # Create comparitive lists of airlines, aircraft and classes:
    @airlines = Airline.flight_count(@flights, type: :airline)
    @aircraft_families = AircraftFamily.flight_count(@flights)
    @classes = TravelClass.flight_count(@flights)
    
    # Create superlatives:
    @route_superlatives = superlatives(@flights)
    
  rescue ActiveRecord::RecordNotFound
    flash[:warning] = "We couldnʼt find any flights operated by #{@operator} with fleet number ##{@fleet_number}. Instead, weʼll give you a list of airlines and operators."
    redirect_to airlines_path
  end
  
  def new
    session[:form_location] = nil
    @title = "New Airline"
    add_breadcrumb "Airlines", "airlines_path"
    add_breadcrumb "New Airline", "new_airline_path"
    @airline = Airline.new
  end
  
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
  
  def edit
    session[:form_location] = nil
    @airline = Airline.find(params[:id])
    add_breadcrumb "Airlines", "airlines_path"
    add_breadcrumb @airline.airline_name, "airline_path(@airline.iata_airline_code)"
    add_breadcrumb "Edit Airline", "edit_airport_path(@airline)"
  end
  
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
  
    def airline_params
      params.require(:airline).permit(:iata_airline_code, :icao_airline_code, :airline_name, :numeric_code, :is_only_operator)
    end
  
end