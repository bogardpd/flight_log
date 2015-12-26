class AirlinesController < ApplicationController
  before_filter :logged_in_user, :only => [:new, :create, :edit, :update, :destroy]
  add_breadcrumb 'Home', 'root_path'
  
  def index
    @airlines_with_no_flights = Airline.all.order(:airline_name)
  end
  
  def show
    if params[:id].to_i > 0
      @airline = Airline.find(params[:id])
    else
      @airline = Airline.where(:iata_airline_code => params[:id]).first
      raise ActiveRecord::RecordNotFound if (@airline.nil?) #all_flights will fail if code does not exist, so check here.
    end
    @title = @airline.airline_name
    
    @flights = @airline.all_flights(logged_in?)
    
    add_breadcrumb 'Airlines', 'airlines_path'
    add_breadcrumb @title, "airline_path(@airline.iata_airline_code)"
    
    rescue ActiveRecord::RecordNotFound
      flash[:record_not_found] = "We couldn't find an airline with an IATA code of #{params[:id]}. Instead, we'll give you a list of airlines."
      #redirect_to airlines_path
      
  end
  
  def new
    @title = "New Airline"
    add_breadcrumb 'Airlines', 'airlines_path'
    add_breadcrumb 'New Airline', 'new_airline_path'
    @airline = Airline.new
  end
  
  def create
    @airline = Airline.new(airline_params)
    if @airline.save
      flash[:success] = "Successfully added #{params[:airline][:airline_name]}!"
      redirect_to @airline
    else
      render 'new'
    end
  end
  
  def edit
    @airline = Airline.find(params[:id])
    add_breadcrumb 'Airlines', 'airlines_path'
    add_breadcrumb @airline.airline_name, 'airline_path(@airline.iata_airline_code)'
    add_breadcrumb 'Edit Airline', 'edit_airport_path(@airline)'
  end
  
  def update
    @airline = Airline.find(params[:id])
    if @airline.update_attributes(airline_params)
      flash[:success] = "Successfully updated airline."
      redirect_to @airline
    else
      render 'edit'
    end
  end
  
  def destroy
    @flights = @airline.all_flights(true)
    if @flights.any?
      flash[:error] = "This airline still has flights and could not be deleted. Please delete all of this airline's flights first."
      redirect_to airline_path(params[:id])
    else
      if (Airline.exists?(params[:id]))
        Airline.find(params[:id]).destroy
      else
        Airline.where(:iata_airport_code => params[:id]).first.destroy
      end
      flash[:success] = "Airline deleted."
      redirect_to airlines_path
    end
  end
  
  private
  
    def airline_params
      params.require(:airline).permit(:iata_airline_code, :airline_name, :is_only_operator)
    end
  
    def logged_in_user
      redirect_to root_path unless logged_in?
    end
  
end