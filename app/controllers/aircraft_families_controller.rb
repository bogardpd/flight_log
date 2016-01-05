class AircraftFamiliesController < ApplicationController
  before_filter :logged_in_user, :only => [:new, :create, :edit, :update, :destroy]
  add_breadcrumb 'Home', 'root_path'
  
  def index
    add_breadcrumb 'Aircraft Families', 'aircraft_families_path'
    if logged_in?
      @flight_aircraft = Flight.where("aircraft_family IS NOT NULL").group("aircraft_family").count
    else # Filter out hidden trips for visitors
      @flight_aircraft = Flight.visitor.where("aircraft_family IS NOT NULL").group("aircraft_family").count
    end
    @title = "Aircraft"
    @meta_description = "A list of the types of planes on which Paul Bogard has flown, and how often he's flown on each."
    
    @aircraft_array = Array.new
    
    if @flight_aircraft.any?
    
      # Set values for sort:
      case params[:sort_category]
      when "aircraft"
        @sort_cat = :aircraft
      when "flights"
        @sort_cat = :flights
      else
        @sort_cat = :flights
      end
    
      case params[:sort_direction]
      when "asc"
        @sort_dir = :asc
      when "desc"
        @sort_dir = :desc
      else
        @sort_dir = :desc
      end
    
      sort_mult = (@sort_dir == :asc ? 1 : -1)
    
      @flight_aircraft.each do |aircraft, count| 
        @aircraft_array.push({:aircraft => aircraft, :count => count})
      end
          
      # Find maxima for graph scaling:
      @aircraft_maximum = @aircraft_array.max_by{|i| i[:count]}[:count]
    
      # Sort aircraft table:
      case @sort_cat
      when :aircraft
        @aircraft_array = @aircraft_array.sort_by { |aircraft| aircraft[:aircraft].downcase }
        @aircraft_array.reverse! if @sort_dir == :desc
      when :flights
        @aircraft_array = @aircraft_array.sort_by { |aircraft| [sort_mult*aircraft[:count], aircraft[:aircraft]] }
      end
    
    end
     
  end
  
  private
  
    def aircraft_family_params
      #params.require(:airline).permit(:iata_airline_code, :airline_name, :is_only_operator)
    end
  
    def logged_in_user
      redirect_to root_path unless logged_in?
    end
  
end