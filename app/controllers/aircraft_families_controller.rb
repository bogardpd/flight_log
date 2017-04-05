class AircraftFamiliesController < ApplicationController
  before_action :logged_in_user, :only => [:new, :create, :edit, :update, :destroy]
  add_breadcrumb 'Home', 'root_path'
  
  def index
    add_breadcrumb 'Aircraft Families', 'aircraft_families_path'
    
    add_admin_action view_context.link_to("Add New Aircraft Family", new_aircraft_family_path)
    
    if logged_in?
      @flight_aircraft_families = Flight.where("aircraft_family_id IS NOT NULL").group("aircraft_family_id").count
    else # Filter out hidden trips for visitors
      @flight_aircraft_families = Flight.visitor.where("aircraft_family_id IS NOT NULL").group("aircraft_family_id").count
    end

    used_aircraft_family_ids = @flight_aircraft_families.keys.uniq
    if @flight_aircraft_families.any?
      @aircraft_families_with_no_flights = AircraftFamily.where("id NOT IN (?)", used_aircraft_family_ids).order(:family_name)
    else
      @aircraft_families_with_no_flights = AircraftFamily.all.order(:family_name)
    end
    
    @title = "Aircraft"
    @meta_description = "A list of the types of planes on which Paul Bogard has flown, and how often heʼs flown on each."
    
    @aircraft_array = Array.new
    
    if @flight_aircraft_families.any?
      aircraft_family_details = AircraftFamily.select("id, iata_aircraft_code, family_name, manufacturer, category").find(used_aircraft_family_ids)
      aircraft_family_names = Hash.new
      aircraft_family_iata_codes = Hash.new
      aircraft_family_manufacturers = Hash.new
      aircraft_family_categories = Hash.new
      aircraft_family_details.each do |aircraft_family|
        aircraft_family_names[aircraft_family.id] = aircraft_family.family_name
        aircraft_family_iata_codes[aircraft_family.id] = aircraft_family.iata_aircraft_code
        aircraft_family_manufacturers[aircraft_family.id] = aircraft_family.manufacturer
        aircraft_family_categories[aircraft_family.id] = aircraft_family.category 
      end
      
      # Prepare aircraft family list:
      @flight_aircraft_families.each do |aircraft_family, count| 
        @aircraft_array.push({name: aircraft_family_names[aircraft_family], iata_code: aircraft_family_iata_codes[aircraft_family], manufacturer: aircraft_family_manufacturers[aircraft_family], category: aircraft_family_categories[aircraft_family], count: count})
      end
          
      # Find maxima for graph scaling:
      @aircraft_maximum = @aircraft_array.max_by{|i| i[:count]}[:count]
    
      # Sort aircraft table:
      sort_params = sort_parse(params[:sort], %w(flights aircraft code), :desc)
      @sort_cat   = sort_params[:category]
      @sort_dir   = sort_params[:direction]
      sort_mult   = (@sort_dir == :asc ? 1 : -1)
      
      case @sort_cat
      when :aircraft
        @aircraft_array = @aircraft_array.sort_by { |aircraft_family| [aircraft_family[:manufacturer].downcase, aircraft_family[:name].downcase] }
        @aircraft_array.reverse! if @sort_dir == :desc
      when :code
        @aircraft_array = @aircraft_array.sort_by { |aircraft_family| aircraft_family[:iata_code] }
        @aircraft_array.reverse! if @sort_dir == :desc
      when :flights
        @aircraft_array = @aircraft_array.sort_by { |aircraft_family| [sort_mult*aircraft_family[:count], aircraft_family[:name]] }
      end
    
    end
     
  end
  
  def show
    @aircraft_family = AircraftFamily.where(iata_aircraft_code: params[:id]).first
    raise ActiveRecord::RecordNotFound if (@aircraft_family.nil?) #all_flights will fail if code does not exist, so check here.    
    
    @logo_used = true
    @title = @aircraft_family.full_name
    @meta_description = "Maps and lists of Paul Bogardʼs flights on #{@aircraft_family.full_name} aircraft."
    @region = current_region(default: :world)
    
    @flights = Flight.flights_table.where(:aircraft_family_id => @aircraft_family)
    @flights = @flights.visitor if !logged_in? # Filter out hidden trips for visitors
    raise ActiveRecord::RecordNotFound if (!logged_in? && @flights.length == 0)
    add_breadcrumb 'Aircraft Families', 'aircraft_families_path'
    add_breadcrumb @aircraft_family.full_name, aircraft_family_path(@aircraft_family.iata_aircraft_code)
    
    add_admin_action view_context.link_to("Delete Aircraft Family", @aircraft_family, method: :delete, data: {:confirm => "Are you sure you want to delete #{@aircraft_family.full_name}?"}, class: 'warning') if @flights.length == 0
    add_admin_action view_context.link_to("Edit Aircraft Family", edit_aircraft_family_path(@aircraft_family))
    
    @map = FlightsMap.new(@flights, region: @region)
    @total_distance = total_distance(@flights)
    
    # Create comparitive lists of airlines and classes:
    airline_frequency(@flights)
    operator_frequency(@flights)
    class_frequency(@flights)
    
    # Create superlatives:
    @route_superlatives = superlatives(@flights)
    
    rescue ActiveRecord::RecordNotFound
      flash[:warning] = "We couldnʼt find an aircraft family with an IATA code of #{params[:id]}. Instead, weʼll give you a list of aircraft families."
      redirect_to aircraft_families_path
  end
  
  def new
    @title = "New Aircraft Family"
    add_breadcrumb 'Aircraft Families', 'aircraft_families_path'
    add_breadcrumb 'New Aircraft Family', 'new_aircraft_family_path'
    @aircraft_family = AircraftFamily.new
  end
  
  def create
    @aircraft_family = AircraftFamily.new(aircraft_family_params)
    if @aircraft_family.save
      flash[:success] = "Successfully added #{params[:aircraft_family][:family_name]}!"
      redirect_to aircraft_family_path(@aircraft_family.iata_aircraft_code)
    else
      render 'new'
    end
  end
  
  def edit
    @aircraft_family = AircraftFamily.find(params[:id])
    add_breadcrumb 'Aircraft Families', 'aircraft_families_path'
    add_breadcrumb @aircraft_family.full_name, 'aircraft_family_path(@aircraft_family.iata_aircraft_code)'
    add_breadcrumb 'Edit Aircraft Family', 'edit_aircraft_family_path(@aircraft_family)'
  end
  
  def update
    @aircraft_family = AircraftFamily.find(params[:id])
    if @aircraft_family.update_attributes(aircraft_family_params)
      flash[:success] = "Successfully updated aircraft family."
      redirect_to aircraft_family_path(@aircraft_family.iata_aircraft_code)
    else
      render 'edit'
    end
  end
  
  def destroy
    @aircraft_family = AircraftFamily.find(params[:id])
    if @aircraft_family.flights.any?
      flash[:error] = "This aircraft family still has flights and could not be deleted. Please delete all of this aircraft familyʼs flights first."
      redirect_to aircraft_family_path(@aircraft_family.iata_aircraft_code)
    else
      @aircraft_family.destroy
      flash[:success] = "Aircraft family deleted."
      redirect_to aircraft_families_path
    end
  end
  
  private
  
    def aircraft_family_params
      params.require(:aircraft_family).permit(:family_name, :iata_aircraft_code, :manufacturer, :category)
    end
  
end