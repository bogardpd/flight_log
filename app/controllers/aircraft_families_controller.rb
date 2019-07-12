# Controls {AircraftFamily} pages and actions.

class AircraftFamiliesController < ApplicationController
  before_action :logged_in_user, :only => [:new, :create, :edit, :update, :destroy]
  
  # Shows a table of all {AircraftFamily AircraftFamilies} flown.
  #
  # @return [nil]
  def index
    @title = "Aircraft"
    @meta_description = "A list of the types of planes on which Paul Bogard has flown, and how often heʼs flown on each."
    add_breadcrumb "Aircraft Families", aircraft_families_path
    add_admin_action view_context.link_to("Add New Aircraft Family", new_aircraft_family_path)
    
    @flights = flyer.flights(current_user)
    @sort = sort_parse(params[:sort], :flights, :desc)
    flight_count = AircraftFamily.flight_count(@flights, *@sort)
    @aircraft_families, @aircraft_families_with_no_flights = flight_count.partition{|a| a[:flight_count] > 0}
    
    if @aircraft_families.any?
      # Find maxima for graph scaling:
      @aircraft_maximum = @aircraft_families.max_by{|i| i[:flight_count]}[:flight_count]
    end     
  end
  
  # Shows details for a particular {AircraftFamily} (either a parent aircraft
  # family or a child aircraft type) and data for all {Flight Flights} flown on
  # it.
  # 
  # {AircraftFamily} details:
  # * a side profile {http://www.norebbo.com/ illustration} of the aircraft
  # * IATA code (if the {AircraftFamily} is a parent aircraft family) or ICAO code (if the {AircraftFamily} is a child aircraft type)
  # * a table of child aircraft types (if the {AircraftFamily} is a parent aircraft family)
  #
  # {Flight} data:
  # * a {FlightsMap}
  # * a table of {Flight Flights}
  # * the total distance flown
  # * a table of {Airline Airlines}
  # * a table of {AirlinesController#show_operator operators}
  # * a table of {FlightsController#show_class classes}
  # * the longest and shortest {Flight}
  #
  # @return [nil]
  # @see http://www.norebbo.com/ Norebbo Stock Illustration and Design
  def show
    @aircraft_family = AircraftFamily.find(params[:id])
    raise ActiveRecord::RecordNotFound if (@aircraft_family.nil?)
    
    @logo_used = true
    @title = @aircraft_family.full_name
    @title += " Family" if @aircraft_family.is_family?
    @meta_description = "Maps and lists of Paul Bogardʼs flights on #{@aircraft_family.full_name} aircraft."
    @region = current_region(default: [])
    
    @flights = flyer.flights(current_user).where(aircraft_family_id: @aircraft_family.family_and_type_ids).includes(:airline, :origin_airport, :destination_airport, :trip)
    raise ActiveRecord::RecordNotFound if (!logged_in? && @flights.length == 0)
    
    add_breadcrumb "Aircraft Families", aircraft_families_path
    
    
    if @aircraft_family.is_family?
      add_breadcrumb @aircraft_family.full_name, aircraft_family_path(@aircraft_family)
      add_admin_action view_context.link_to("Delete Aircraft Family", @aircraft_family, method: :delete, data: {:confirm => "Are you sure you want to delete #{@aircraft_family.full_name}?"}, class: "warning") if @flights.length == 0 && !@aircraft_family.children.any?
      add_admin_action view_context.link_to("Edit Aircraft Family", edit_aircraft_family_path(@aircraft_family))
      add_admin_action view_context.link_to("Add Subtype", new_aircraft_family_path(family_id: @aircraft_family))
    else
      family = @aircraft_family.parent
      add_breadcrumb family.full_name, aircraft_family_path(family)
      add_breadcrumb @aircraft_family.family_name, aircraft_family_path(@aircraft_family)
      add_admin_action view_context.link_to("Delete Aircraft Type", @aircraft_family, method: :delete, data: {:confirm => "Are you sure you want to delete #{@aircraft_family.full_name}?"}, class: "warning") if @flights.length == 0
      add_admin_action view_context.link_to("Edit Aircraft Type", edit_aircraft_family_path(@aircraft_family))
    end
    
    @map = FlightsMap.new(@flights, region: @region)
    @total_distance = Route.total_distance(@flights)
    
    @subtypes = @aircraft_family.family_and_type_count(@flights)
    @subtypes_with_no_flights = AircraftFamily.with_no_flights.where(parent_id: @aircraft_family)
    
    # Create comparitive lists of airlines and classes:
    @airlines = Airline.flight_count(@flights, type: :airline)
    @operators = Airline.flight_count(@flights, type: :operator)
    @classes = TravelClass.flight_count(@flights)
    
    # Create superlatives:
    @route_superlatives = superlatives(@flights)
    
    rescue ActiveRecord::RecordNotFound
      flash[:warning] = "We couldnʼt find an aircraft family with an ID of #{params[:id]}. Instead, weʼll give you a list of aircraft families."
      redirect_to aircraft_families_path
  end
  
  # Shows a form to add an {AircraftFamily} (either a parent aircraft family or
  # a child aircraft type).
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def new
    session[:form_location] = nil
    add_breadcrumb "Aircraft Families", aircraft_families_path
    if params[:family_id]
      @parent_family = AircraftFamily.find(params[:family_id])
      @title = "New #{@parent_family.family_name} Type"
      add_breadcrumb @parent_family.full_name, aircraft_family_path(@parent_family)
      add_breadcrumb @title, "new_aircraft_family_path(family_id: #{@parent_family.id})"
      @aircraft_family = AircraftFamily.new(parent_id: @parent_family.id)
    else
      @title = "New Aircraft Family"
      add_breadcrumb "New Aircraft Family", new_aircraft_family_path
      @aircraft_family = AircraftFamily.new
    end
    
    
    rescue ActiveRecord::RecordNotFound
      flash[:warning] = "We couldnʼt find an aircraft family with an ID of #{params[:family_id]}. Instead, weʼll give you a list of aircraft families."
      redirect_to aircraft_families_path
  end
  
  # Creates a new {AircraftFamily} (either a parent aircraft family or a child
  # aircraft type).
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def create
    @aircraft_family = AircraftFamily.new(aircraft_family_params)
    if @aircraft_family.save
      flash[:success] = "Successfully added #{params[:aircraft_family][:family_name]}!"
      if session[:form_location]
        form_location = session[:form_location]
        session[:form_location] = nil
        redirect_to form_location
      else
        redirect_to aircraft_family_path(@aircraft_family)
      end
    else
      if session[:form_location]
        render "flights/new_undefined_aircraft_family"
      else
        render "new"
      end
    end
  end
  
  # Shows a form to edit an existing {AircraftFamily} (either a parent aircraft
  # family or a child aircraft type).
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def edit
    session[:form_location] = nil
    @aircraft_family = AircraftFamily.find(params[:id])
    add_breadcrumb "Aircraft Families", aircraft_families_path
    add_breadcrumb @aircraft_family.full_name, aircraft_family_path(@aircraft_family)
    add_breadcrumb "Edit Aircraft Family", edit_aircraft_family_path(@aircraft_family)
  end
  
  # Updates an existing {AircraftFamily} (either a parent aircraft family or a
  # child aircraft type).
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def update
    @aircraft_family = AircraftFamily.find(params[:id])
    if @aircraft_family.update_attributes(aircraft_family_params)
      flash[:success] = "Successfully updated aircraft family."
      redirect_to aircraft_family_path(@aircraft_family)
    else
      render "edit"
    end
  end
  
  # Deletes an existing {AircraftFamily} (either a parent aircraft family or a
  # child aircraft type).
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def destroy
    @aircraft_family = AircraftFamily.find(params[:id])
    @children = AircraftFamily.where(parent_id: params[:id])
    if @aircraft_family.flights.any?
      flash[:error] = "This aircraft family still has flights and could not be deleted. Please delete all of this aircraft familyʼs flights first."
      redirect_to aircraft_family_path(@aircraft_family)
    elsif @children.any?
      flash[:error] = "This aircraft family still has variants that belong to it and could not be deleted. Please delete all of this aircraft familyʼs variants first."
      redirect_to aircraft_family_path(@aircraft_family)
    else
      @aircraft_family.destroy
      flash[:success] = "Aircraft family deleted."
      redirect_to aircraft_families_path
    end
  end
  
  private
  
  # Defines permitted {AircraftFamily} parameters.
  #
  # @return [ActionController::Parameters]
  def aircraft_family_params
    params.require(:aircraft_family).permit(:family_name, :icao_aircraft_code, :iata_aircraft_code, :manufacturer, :category, :parent_id)
  end
  
end