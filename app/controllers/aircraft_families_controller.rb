# Controls {AircraftFamily} pages and actions.

class AircraftFamiliesController < ApplicationController
  before_action :logged_in_user, :only => [:new, :create, :edit, :update, :destroy]
  
  # Shows a table of all {AircraftFamily AircraftFamilies} flown.
  #
  # @return [nil]
  def index
    @flights = flyer.flights(current_user)
    @sort = Table.sort_parse(params[:sort], :flights, :desc)
    flight_count = AircraftFamily.flight_table_data(@flights, *@sort, include_families_with_no_flights: true)
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
  # * IATA code and ICAO code
  # * a table of child aircraft types
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
    @aircraft = AircraftFamily.find_by(slug: params[:id])
    raise ActiveRecord::RecordNotFound if (@aircraft.nil?)
    
    @logo_used = true
    @region = current_region(default: [])
    
    @flights = flyer.flights(current_user).where(aircraft_family_id: @aircraft.family_and_type_ids).includes(:airline, :origin_airport, :destination_airport, :trip)
    raise ActiveRecord::RecordNotFound if (!logged_in? && @flights.length == 0)
    
    @map = FlightsMap.new(:aircraft_family_map, @flights, region: @region)
    @total_distance = @flights.total_distance
    
    @children = @aircraft.children
    @flights_including_child_types = @aircraft.family_and_type_count(@flights)
    @child_types_with_no_flights = AircraftFamily.with_no_flights.where(parent_id: @aircraft)
    
    # Create summary info
    @summary_items = Hash.new
    @summary_items.store("Manufacturer", @aircraft.manufacturer)
    @summary_items.store("IATA", @aircraft.iata_code) if @aircraft.iata_code.present?
    @summary_items.store("ICAO", @aircraft.icao_code) if @aircraft.icao_code.present?
    @summary_items.store("Subtype of", view_context.link_to(@aircraft.parent.name, aircraft_family_path(@aircraft.parent.slug), title: "View flights on #{@aircraft.parent.full_name} aircraft")) if @aircraft.parent.present?

    # Create comparitive lists of airlines and classes:
    @airlines = Airline.flight_table_data(@flights, type: :airline)
    @operators = Airline.flight_table_data(@flights, type: :operator)
    @classes = TravelClass.flight_table_data(@flights)
    
    # Create superlatives:
    @route_superlatives = @flights.superlatives
    
    rescue ActiveRecord::RecordNotFound
      flash[:warning] = %Q(We couldnʼt find an aircraft family matching <span class="param-highlight">#{params[:id]}</span>. Instead, weʼll give you a list of aircraft families.)
      redirect_to aircraft_families_path
  end
  
  # Shows a form to add an {AircraftFamily}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def new
    session[:form_location] = nil
    
    if params[:family_id]
      @parent_family = AircraftFamily.find(params[:family_id])
      @aircraft = AircraftFamily.new(parent_id: @parent_family.id)
      @title = "New #{@parent_family.name} Type"
    else
      @title = "New Aircraft Family"
      @aircraft = AircraftFamily.new
    end
    
    rescue ActiveRecord::RecordNotFound
      flash[:warning] = "We couldnʼt find an aircraft family matching #{params[:family_id]}. Instead, weʼll give you a list of aircraft families."
      redirect_to aircraft_families_path
  end
  
  # Creates a new {AircraftFamily}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def create
    @aircraft = AircraftFamily.new(aircraft_family_params)
    if @aircraft.save
      flash[:success] = "Successfully added #{params[:aircraft_family][:name]}!"
      if session[:form_location]
        form_location = session[:form_location]
        session[:form_location] = nil
        redirect_to form_location
      else
        redirect_to aircraft_family_path(@aircraft.slug)
      end
    else
      if session[:form_location]
        render "flights/new_undefined_aircraft_family"
      else
        render "new"
      end
    end
  end
  
  # Shows a form to edit an existing {AircraftFamily}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def edit
    session[:form_location] = nil
    @aircraft = AircraftFamily.find(params[:id])    
  end
  
  # Updates an existing {AircraftFamily}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def update
    @aircraft = AircraftFamily.find(params[:id])
    if @aircraft.update(aircraft_family_params)
      flash[:success] = "Successfully updated aircraft family."
      redirect_to aircraft_family_path(@aircraft.slug)
    else
      render "edit"
    end
  end
  
  # Deletes an existing {AircraftFamily}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def destroy
    @aircraft = AircraftFamily.find(params[:id])
    @children = AircraftFamily.where(parent_id: params[:id])
    @parent = @aircraft.parent
    if @aircraft.flights.any?
      flash[:error] = "This aircraft still has flights and could not be deleted. Please delete all of this aircraftʼs flights first."
      redirect_to aircraft_family_path(@aircraft.slug)
    elsif @children.any?
      flash[:error] = "This aircraft still has types that belong to it and could not be deleted. Please delete all of this aircraftʼs types first."
      redirect_to aircraft_family_path(@aircraft.slug)
    else
      @aircraft.destroy
      flash[:success] = "Aircraft deleted."
      if @parent
        redirect_to(aircraft_family_path(@parent.slug))
      else
        redirect_to(aircraft_families_path)
      end
    end
  end
  
  private
  
  # Defines permitted {AircraftFamily} parameters.
  #
  # @return [ActionController::Parameters]
  def aircraft_family_params
    params.require(:aircraft_family).permit(:name, :slug, :icao_code, :iata_code, :manufacturer, :category, :parent_id)
  end
  
end