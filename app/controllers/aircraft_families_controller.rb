class AircraftFamiliesController < ApplicationController
  before_action :logged_in_user, :only => [:new, :create, :edit, :update, :destroy]
  add_breadcrumb 'Home', 'root_path'
  
  def index
    @title = "Aircraft"
    @meta_description = "A list of the types of planes on which Paul Bogard has flown, and how often heʼs flown on each."
    add_breadcrumb "Aircraft Families", "aircraft_families_path"
    add_admin_action view_context.link_to("Add New Aircraft Family", new_aircraft_family_path)
    
    flights = flyer.flights(current_user)
    flight_count = AircraftFamily.flight_count(flights)
    @aircraft_families, @aircraft_families_with_no_flights = flight_count.partition{|a| a[:flight_count] > 0}
    
    if @aircraft_families.any?
            
      # Find maxima for graph scaling:
      @aircraft_maximum = @aircraft_families.max_by{|i| i[:flight_count]}[:flight_count]
    
      # Sort aircraft table:
      sort_params = sort_parse(params[:sort], %w(flights aircraft code), :desc)
      @sort_cat   = sort_params[:category]
      @sort_dir   = sort_params[:direction]
      sort_mult   = (@sort_dir == :asc ? 1 : -1)
      
      case @sort_cat
      when :aircraft
        @aircraft_families = @aircraft_families.sort_by { |aircraft_family| [aircraft_family[:manufacturer]&.downcase || "", aircraft_family[:family_name]&.downcase || ""] }
        @aircraft_families.reverse! if @sort_dir == :desc
      when :code
        @aircraft_families = @aircraft_families.sort_by { |aircraft_family| aircraft_family[:iata_aircraft_code] || "" }
        @aircraft_families.reverse! if @sort_dir == :desc
      when :flights
        @aircraft_families = @aircraft_families.sort_by { |aircraft_family| [sort_mult*aircraft_family[:flight_count], aircraft_family[:family_name]&.downcase || ""] }
      end
    end     
  end
  
  def show
    @aircraft_family = AircraftFamily.find(params[:id])
    raise ActiveRecord::RecordNotFound if (@aircraft_family.nil?) #all_flights will fail if code does not exist, so check here.    
    
    @logo_used = true
    @title = @aircraft_family.full_name
    @title += " Family" if @aircraft_family.is_family?
    @meta_description = "Maps and lists of Paul Bogardʼs flights on #{@aircraft_family.full_name} aircraft."
    @region = current_region(default: :world)
    
    @flights = flyer.flights(current_user).where(aircraft_family_id: @aircraft_family.family_and_subtype_ids).includes(:airline, :origin_airport, :destination_airport, :trip)
    raise ActiveRecord::RecordNotFound if (!logged_in? && @flights.length == 0)
    
    add_breadcrumb 'Aircraft Families', 'aircraft_families_path'
    
    
    if @aircraft_family.is_family?
      add_breadcrumb @aircraft_family.full_name, aircraft_family_path(@aircraft_family)
      add_admin_action view_context.link_to("Delete Aircraft Family", @aircraft_family, method: :delete, data: {:confirm => "Are you sure you want to delete #{@aircraft_family.full_name}?"}, class: 'warning') if @flights.length == 0
      add_admin_action view_context.link_to("Edit Aircraft Family", edit_aircraft_family_path(@aircraft_family))
      add_admin_action view_context.link_to("Add Subtype", new_aircraft_family_path(family_id: @aircraft_family))
    else
      family = @aircraft_family.parent
      add_breadcrumb family.full_name, aircraft_family_path(family)
      add_breadcrumb @aircraft_family.family_name, aircraft_family_path(@aircraft_family)
      add_admin_action view_context.link_to("Delete Aircraft Type", @aircraft_family, method: :delete, data: {:confirm => "Are you sure you want to delete #{@aircraft_family.full_name}?"}, class: 'warning') if @flights.length == 0
      add_admin_action view_context.link_to("Edit Aircraft Type", edit_aircraft_family_path(@aircraft_family))
    end
    
    @map = FlightsMap.new(@flights, region: @region)
    @total_distance = total_distance(@flights)
    
    @subtypes = @aircraft_family.family_and_subtype_count(@flights)
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
  
  def new
    add_breadcrumb 'Aircraft Families', 'aircraft_families_path'
    if params[:family_id]
      @parent_family = AircraftFamily.find(params[:family_id])
      @title = "New #{@parent_family.family_name} Type"
      add_breadcrumb @parent_family.full_name, aircraft_family_path(@parent_family)
      add_breadcrumb @title, "new_aircraft_family_path(family_id: #{@parent_family.id})"
      @aircraft_family = AircraftFamily.new(parent_id: @parent_family.id)
    else
      @title = "New Aircraft Family"
      add_breadcrumb 'New Aircraft Family', 'new_aircraft_family_path'
      @aircraft_family = AircraftFamily.new
    end
    
    
    rescue ActiveRecord::RecordNotFound
      flash[:warning] = "We couldnʼt find an aircraft family with an ID of #{params[:family_id]}. Instead, weʼll give you a list of aircraft families."
      redirect_to aircraft_families_path
  end
  
  def create
    @aircraft_family = AircraftFamily.new(aircraft_family_params)
    if @aircraft_family.save
      flash[:success] = "Successfully added #{params[:aircraft_family][:family_name]}!"
      redirect_to aircraft_family_path(@aircraft_family)
    else
      render 'new'
    end
  end
  
  def edit
    @aircraft_family = AircraftFamily.find(params[:id])
    add_breadcrumb 'Aircraft Families', 'aircraft_families_path'
    add_breadcrumb @aircraft_family.full_name, 'aircraft_family_path(@aircraft_family)'
    add_breadcrumb 'Edit Aircraft Family', 'edit_aircraft_family_path(@aircraft_family)'
  end
  
  def update
    @aircraft_family = AircraftFamily.find(params[:id])
    if @aircraft_family.update_attributes(aircraft_family_params)
      flash[:success] = "Successfully updated aircraft family."
      redirect_to aircraft_family_path(@aircraft_family)
    else
      render 'edit'
    end
  end
  
  def destroy
    @aircraft_family = AircraftFamily.find(params[:id])
    if @aircraft_family.flights.any?
      flash[:error] = "This aircraft family still has flights and could not be deleted. Please delete all of this aircraft familyʼs flights first."
      redirect_to aircraft_family_path(@aircraft_family)
    else
      @aircraft_family.destroy
      flash[:success] = "Aircraft family deleted."
      redirect_to aircraft_families_path
    end
  end
  
  private
  
    def aircraft_family_params
      params.require(:aircraft_family).permit(:family_name, :icao_aircraft_code, :iata_aircraft_code, :manufacturer, :category, :parent_id)
    end
  
end