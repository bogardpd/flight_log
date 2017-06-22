class FlightsController < ApplicationController
  protect_from_forgery except: :show_boarding_pass_json
  before_action :logged_in_user, :only => [:new, :new_undefined_fields, :create, :create_iata, :edit, :edit_with_pass, :update, :destroy, :index_emails, :new_undefined_fields, :create_iata]
  add_breadcrumb 'Home', 'root_path'
  
  def index
    add_breadcrumb 'Flights', 'flights_path'
    @logo_used = true
    @title = "Flights"
    @region = current_region(default: :world)
        
    if logged_in?
      @flights = Flight.flights_table
    else
      @flights = Flight.flights_table.visitor
    end
    
    @year_range = @flights.year_range
    
    if @flights.any?
    
      @map = FlightsMap.new(@flights, region: @region)
      
      @total_distance = total_distance(@flights)
    
      # Determine which years have flights:
      @years_with_flights = Hash.new(false)
      @flights.each do |flight|
        @years_with_flights[flight.departure_date.year] = true
      end
      @meta_description = "Maps and lists of all of Paul Bogardʼs flights."
    
      # Sort flight table:
      sort_params = sort_parse(params[:sort], %w(departure), :asc)
      @sort_cat   = sort_params[:category]
      @sort_dir   = sort_params[:direction]
      @flights = @flights.reverse_order if @sort_dir == :desc
    
    end
  
  end
  
  def show
    @logo_used = true
    if logged_in?
      @flight = Flight.find(params[:id])
      @city_pair_flights = Flight.where("(origin_airport_id = :city1 AND destination_airport_id = :city2) OR (origin_airport_id = :city2 AND destination_airport_id = :city1)", {:city1 => @flight.origin_airport.id, :city2 => @flight.destination_airport.id})
      check_email_for_boarding_passes if @flight.trip.hidden?
    else
      @flight = Flight.visitor.find(params[:id])
      @city_pair_flights = Flight.visitor.where("(origin_airport_id = :city1 AND destination_airport_id = :city2) OR (origin_airport_id = :city2 AND destination_airport_id = :city1)", {:city1 => @flight.origin_airport.id, :city2 => @flight.destination_airport.id})
    end
    
    add_message(:warning, "This flight is part of a #{view_context.link_to("hidden trip", trip_path(@flight.trip))}!") if @flight.trip.hidden
    updated_pass = PKPass.where(flight_id: @flight)
    if updated_pass.any?
      add_message(:info, "This flight has an #{view_context.link_to("updated boarding pass", edit_flight_with_pass_path(pass_id: updated_pass.first))} available!")
    end
    
    # Create map:
    @map = SingleFlightMap.new(@flight)
    
    # Get trips sharing this city pair:
    trip_array = Array.new
    @city_pair_flights = Array.new
    section_where_array = Array.new
    @city_pair_flights.each do |flight|
      trip_array.push(flight.trip_id)
      @sections.push( {:trip_id => flight.trip_id, :trip_name => flight.trip.name, :trip_section => flight.trip_section, :departure => flight.departure_date} )
      section_where_array.push("(trip_id = #{flight.trip_id.to_i} AND trip_section = #{flight.trip_section.to_i})")
    end
    trip_array = trip_array.uniq
    
    # Create list of trips sorted by first flight:
    if logged_in?
      @trips = Trip.find(trip_array).sort_by{ |trip| trip.flights.first.departure_date }
    else
      @trips = Trip.visitor.find(trip_array).sort_by{ |trip| trip.flights.first.departure_date }
    end
    
    # Create flight arrays for maps of trips and sections:
    @city_pair_trip_flights = Flight.where(:trip_id => trip_array)
    @city_pair_section_flights = Flight.where(section_where_array.join(' OR '))
    
    @title = @flight.airline.airline_name + " " + @flight.flight_number.to_s
    @meta_description = "Details for Paul Bogardʼs #{@flight.airline.airline_name} #{@flight.flight_number} flight on #{format_date(@flight.departure_date)}."
    
    @route_distance = Route.distance_by_airport_id(@flight.origin_airport, @flight.destination_airport)
    
    @boarding_pass = BoardingPass.new(@flight.boarding_pass_data, flight: @flight)
    
    add_breadcrumb 'Flights', 'flights_path'
    add_breadcrumb @title, "flight_path(#{params[:id]})"
    
    add_admin_action view_context.link_to("Delete Flight", :flight, :method => :delete, :data => {:confirm => "Are you sure you want to delete this flight?"}, :class => 'warning')
    add_admin_action view_context.link_to("Edit Flight", edit_flight_path(@flight))
    
  rescue ActiveRecord::RecordNotFound
    flash[:warning] = "We couldnʼt find a flight with an ID of #{params[:id]}. Instead, weʼll give you a list of flights."
    redirect_to flights_path
  end
    
  def show_date_range
    add_breadcrumb 'Flights', 'flights_path'
    @logo_used = true
    
    if params[:year].present?
      @date_range = ("#{params[:year]}-01-01".to_date)..("#{params[:year]}-12-31".to_date)
      add_breadcrumb params[:year], "flights_path(:year => #{params[:year]})"
      @date_range_text = "in #{params[:year]}"
      @flight_list_title = params[:year] + " Flight List"
      @superlatives_title = params[:year] + " Longest and Shortest Routes"
      @superlatives_title_nav = @superlatives_title.downcase
      @title = "Flights in #{params[:year]}"
      @meta_description = "Maps and lists of Paul Bogardʼs flights in #{params[:year]}"
    elsif (params[:start_date].present? && params[:end_date].present?)
      if (params[:start_date] > params[:end_date])
        raise ArgumentError.new('Start date cannot be later than end date')
      end

      @date_range = (params[:start_date].to_date)..(params[:end_date].to_date)
      add_breadcrumb "#{format_date(params[:start_date].to_date)} - #{format_date(params[:end_date].to_date)}", "flights_path(:start_date => '#{params[:start_date]}', :end_date => '#{params[:end_date]}')"
      @date_range_text = "from #{format_date(params[:start_date].to_date)} to #{format_date(params[:end_date].to_date)}"
      @flight_list_title = "Flight List for #{format_date(params[:start_date].to_date)} to #{format_date(params[:end_date].to_date)}"
      @superlatives_title = "Longest and Shortest Routes for#{format_date(params[:start_date].to_date)} to #{format_date(params[:end_date].to_date)}"
      @superlatives_title_nav = "Longest and shortest routes for#{format_date(params[:start_date].to_date)} to #{format_date(params[:end_date].to_date)}"
      @title = "Flights: #{format_date(params[:start_date].to_date)} – #{format_date(params[:end_date].to_date)}"
      @meta_description = "Maps and lists of Paul Bogardʼs flights from #{format_date(params[:start_date].to_date)} to #{format_date(params[:end_date].to_date)}"
    else
      raise ArgumentError.new('No date parameters were given for a date range')
    end
    
    @in_text = params[:year].present? ? params[:year] : "this date range"
    
    filtered_flights = Flight.where(:departure_date => @date_range)
    if logged_in?
      @flights = filtered_flights.flights_table
      @year_range = Flight.year_range
      @years_with_flights = Flight.years_with_flights
    else
      @flights = filtered_flights.visitor.flights_table
      @year_range = Flight.visitor.year_range
      @years_with_flights = Flight.visitor.years_with_flights
    end
    
    raise ActiveRecord::RecordNotFound if @flights.length == 0
    
    @region = current_region(default: :world)
    @map = FlightsMap.new(@flights, region: @region)
    @total_distance = total_distance(@flights)
      
    # Create comparitive lists of airlines and classes:
    @airports = Airport.visit_count(logged_in?, flights: filtered_flights) 
    @airlines = Airline.flight_count(logged_in?, type: :airline, flights: filtered_flights) 
    @aircraft_families = AircraftFamily.flight_count(logged_in?, flights: filtered_flights)
    @classes = TravelClass.flight_count(logged_in?, flights: filtered_flights)
    @new_airports = Airport.new_in_date_range(@date_range, logged_in?)
    @new_airlines = Airline.new_in_date_range(@date_range, logged_in?)   
    @new_aircraft_families = AircraftFamily.new_in_date_range(@date_range, logged_in?)
    @new_classes = Flight.new_class_in_date_range(@date_range, logged_in?)
    
    # Create superlatives:
    @route_superlatives = superlatives(@flights)
    
  rescue ArgumentError
    redirect_to flights_path
    
  rescue ActiveRecord::RecordNotFound
    flash[:warning] = "We couldnʼt find any flights in #{@in_text}. Instead, weʼll give you a list of flights."
    redirect_to flights_path
    
  end
    
  def index_classes
    add_breadcrumb 'Travel Classes', 'classes_path'
    
    @classes = TravelClass.flight_count(logged_in?)
    
    @title = "Travel Classes"
    @meta_description = "A count of how many times Paul Bogard has flown in each class."
    
    if @classes.any?
                
      # Sort aircraft table:
      sort_params = sort_parse(params[:sort], %w(class flights), :asc)
      @sort_cat   = sort_params[:category]
      @sort_dir   = sort_params[:direction]
      sort_mult   = (@sort_dir == :asc ? 1 : -1)
      case @sort_cat
      when :class
        @classes = @classes.sort_by { |tc| tc[:class_code] || "" }
        @classes.reverse! if @sort_dir == :desc
      when :flights
        @classes = @classes.sort_by { |tc| [sort_mult*tc[:flight_count], tc[:class_code] || ""] }
      end
      
    end
  end
  
  def show_class
    @logo_used = true
    
    filtered_flights = Flight.where(:travel_class => params[:travel_class])
    @flights = filtered_flights.flights_table
    @flights = @flights.visitor if !logged_in? # Filter out hidden trips for visitors
    
    @title = TravelClass.list[params[:travel_class]].titlecase + " Class"
    @meta_description = "Maps and lists of Paul Bogardʼs #{TravelClass.list[params[:travel_class]].downcase} class flights."
    raise ActiveRecord::RecordNotFound if @flights.length == 0
    add_breadcrumb 'Travel Classes', 'classes_path'
    add_breadcrumb TravelClass.list[params[:travel_class]].titlecase, show_class_path(params[:travel_class])

    @region = current_region(default: :world)
    @map = FlightsMap.new(@flights, region: @region)
    @total_distance = total_distance(@flights)

    # Create comparitive lists of airlines, operators, and aircraft:
    @airlines = Airline.flight_count(logged_in?, type: :airline, flights: filtered_flights)
    @operators = Airline.flight_count(logged_in?, type: :operator, flights: filtered_flights)
    @aircraft_families = AircraftFamily.flight_count(logged_in?, flights: filtered_flights)

    # Create superlatives:
    @route_superlatives = superlatives(@flights)
    
  rescue ActiveRecord::RecordNotFound
    flash[:warning] = "We couldnʼt find any flights in #{@title}. Instead, weʼll give you a list of travel classes."
    redirect_to classes_path
  end

  def index_tails
    add_breadcrumb 'Tail Numbers', 'tails_path'
    if logged_in?
      @flight_tail_numbers = Flight.where("tail_number IS NOT NULL").group("tail_number").count
      @flight_tail_details = Flight.select(:tail_number, :iata_aircraft_code, :airline_name, :iata_airline_code, :family_name, :manufacturer).joins(:airline, :aircraft_family).chronological.where("tail_number IS NOT NULL")
    else # Filter out hidden trips for visitors
      @flight_tail_numbers = Flight.visitor.where("tail_number IS NOT NULL").group("tail_number").count
      @flight_tail_details = Flight.visitor.select(:tail_number, :iata_aircraft_code, :airline_name, :iata_airline_code, :family_name, :manufacturer).joins(:airline, :aircraft_family).chronological.where("tail_number IS NOT NULL")
    end
    @title = "Tail Numbers"
    @meta_description = "A list of the individual airplanes Paul Bogard has flown on, and how often heʼs flown on each."
    
    @tail_numbers_table = Array.new
    
    if @flight_tail_numbers.any?
      
      @tail_numbers_table = TailNumber.flight_count(logged_in?)
    
      # Find maxima for graph scaling:
      @flights_maximum = @tail_numbers_table.max_by{|i| i[:count]}[:count]
    
      # Sort tails table:
      sort_params = sort_parse(params[:sort], %w(flights tail aircraft airline), :desc)
      @sort_cat   = sort_params[:category]
      @sort_dir   = sort_params[:direction]
      sort_mult   = (@sort_dir == :asc ? 1 : -1)
      case @sort_cat
      when :tail
        @tail_numbers_table = @tail_numbers_table.sort_by {|tail| tail[:tail_number]}
        @tail_numbers_table.reverse! if @sort_dir == :desc
      when :flights
        @tail_numbers_table = @tail_numbers_table.sort_by {|tail| [sort_mult*tail[:count], tail[:tail_number]]}
      when :aircraft
        @tail_numbers_table = @tail_numbers_table.sort_by {|tail| [tail[:aircraft], tail[:airline_name]]}
        @tail_numbers_table.reverse! if @sort_dir == :desc
      when :airline
        @tail_numbers_table = @tail_numbers_table.sort_by {|tail| [tail[:airline_name], tail[:aircraft]]}
        @tail_numbers_table.reverse! if @sort_dir == :desc
      end
    end
  end
  
  def show_tail
    @logo_used = true
    filtered_flights = Flight.where(:tail_number => params[:tail_number])
    @flights = filtered_flights.flights_table
    @flights = @flights.visitor if !logged_in? # Filter out hidden trips for visitors
    
    raise ActiveRecord::RecordNotFound if @flights.length == 0
    @title = params[:tail_number]
    @meta_description = "Maps and lists of Paul Bogardʼs flights on tail number #{params[:tail_number]}."
    add_breadcrumb 'Tail Numbers', 'tails_path'
    add_breadcrumb @title, show_tail_path(params[:tail_number])
    
    @region = current_region(default: :world)
    @map = FlightsMap.new(@flights, region: @region)
    @total_distance = total_distance(@flights)
    
    # Create comparitive list of airlines, operators, and classes:
    @airlines = Airline.flight_count(logged_in?, type: :airline, flights: filtered_flights)
    @operators = Airline.flight_count(logged_in?, type: :operator, flights: filtered_flights)
    @classes = TravelClass.flight_count(logged_in?, flights: filtered_flights)
    
    # Create superlatives:
    @route_superlatives = superlatives(@flights)
    
  rescue ActiveRecord::RecordNotFound
   flash[:warning] = "We couldnʼt find any flights with the tail number #{params[:tail_number]}. Instead, weʼll give you a list of tail numbers."
    redirect_to tails_path
  end
  
  def input_boarding_pass
    @title = "Boarding Pass Parser"
    @meta_description = "A boarding pass barcode parser."
    add_breadcrumb @title, boarding_pass_path
  end
  
  def build_boarding_pass
    if params[:data].present?
      redirect_to show_boarding_pass_path(params[:data])
    else
      flash[:error] = "Boarding pass data cannot be blank."
      redirect_to boarding_pass_path
    end
  end
  
  def show_boarding_pass
    @title = "Boarding Pass Results"
    @meta_description = "Results from the boarding pass barcode parser."
    add_breadcrumb "Boarding Pass", boarding_pass_path
    
    @boarding_pass = BoardingPass.new(params[:data])
    #if @boarding_pass.leg_operating_carrier_designator(0)
    if @boarding_pass.data.dig(:repeated, 0, :mandatory, 42)
      bp_string = "#{@boarding_pass.data.dig(:repeated, 0, :mandatory, 42, :raw)} #{@boarding_pass.data.dig(:repeated, 0, :mandatory, 43, :raw)} #{@boarding_pass.data.dig(:repeated, 0, :mandatory, 26, :raw)} ✈ #{@boarding_pass.data.dig(:repeated, 0, :mandatory, 38, :raw)}"
      @title += ": #{bp_string}"
      add_breadcrumb bp_string, boarding_pass_path
    else
      add_breadcrumb "Results", boarding_pass_path
    end
    
  end
  
  def show_boarding_pass_json
    boarding_pass = BoardingPass.new(params[:data])
    if params[:callback]
      render :json => boarding_pass.data, :callback => params[:callback]
    else
      render :json => boarding_pass.data
    end
  end
  
  def new
    @title = "New Flight"
    add_breadcrumb 'Flights', 'flights_path'
    add_breadcrumb 'New Flight', 'new_flight_path'
    trip = Trip.find(params[:trip_id])
    existing_trip_flights_count = trip.flights.length
    if existing_trip_flights_count > 0
      last_flight = trip.flights.chronological.last
    end
    @flight = trip.flights.new
    
    @pass = PKPass.find_by(id: params[:pass_id])
    if @pass.nil?
      @fields = Hash.new
      @default_trip_section = 1 unless existing_trip_flights_count > 0
    else
      fields = @pass.updated_values(@flight, true) || {}
      add_message(:warning, fields[:error][:label]) if fields[:error]
      check_for_new_iata_codes(fields)
      if existing_trip_flights_count > 0
        pass_datetime = fields.dig(:departure_utc, :pass_value)
        if pass_datetime >= last_flight.departure_utc + 1.day
          @default_trip_section = last_flight.trip_section + 1
        else
          @default_trip_section = last_flight.trip_section
        end
      else
        @default_trip_section = 1
      end
      @fields = fields.reject{|k,v| v[:pass_value].nil?}
    end
  end
  
  def new_undefined_fields
    
  end
    
  def create
    @flight = Trip.find(params[:flight][:trip_id]).flights.new(flight_params)
    if @flight.save
      flash[:success] = "Successfully added #{@flight.airline.airline_name} #{@flight.flight_number}."
      if (@flight.tail_number.present? && Flight.where(:tail_number => @flight.tail_number).count > 1)
        flash[:success] += " Youʼve had prior flights on this tail!"
      end
      if (@flight.departure_date.to_time - @flight.departure_utc.to_time).to_i.abs > 60*60*24*2
        flash[:warning] = "Your departure date and UTC time are more than a day apart &ndash; are you sure theyʼre correct?".html_safe
      end
      # If pass exists, delete pass 
      if params[:flight][:pass_id]
        pass = PKPass.find(params[:flight][:pass_id])
        pass.destroy if pass
      end
      redirect_to @flight
    else
      render 'new'
    end
  end
  
  def create_iata_icao
    (0..(params[:count].to_i-1)).each do |index|
      type = params["type_#{index}".to_sym]
      next if type.nil?
      prefix = "#{type}_#{index}_"
      case type
      when "airline"
        if params[(prefix+"iata").to_sym] && params[(prefix+"name").to_sym]
          Airline.create(iata_airline_code: params[(prefix+"iata").to_sym], airline_name: params[(prefix+"name").to_sym], icao_airline_code: params[(prefix+"icao_code").to_sym], numeric_code: params[(prefix+"numeric_code").to_sym], is_only_operator: false)
        end
      when "airport"
        if params[(prefix+"iata").to_sym] && params[(prefix+"name").to_sym] && params[(prefix+"country").to_sym]
          Airport.create(iata_code: params[(prefix+"iata").to_sym], city: params[(prefix+"name").to_sym], country: params[(prefix+"country").to_sym], region_conus: params[(prefix+"region_conus").to_sym])
        end
      when "aircraft"
        if (params[(prefix+"iata").to_sym] || params[(prefix+"iata").to_sym]) && params[(prefix+"name").to_sym] && params[(prefix+"family").to_sym]
          parent = AircraftFamily.find_by(parent_id: params[(prefix+"family").to_sym])
          if parent
            manufacturer = parent.manufacturer
            category = parent.category
          end
          AircraftFamily.create(iata_aircraft_code: params[(prefix+"iata").to_sym], icao_aircraft_code: params[(prefix+"icao").to_sym], family_name: params[(prefix+"name").to_sym], parent_id: params[(prefix+"family").to_sym], manufacturer: manufacturer, category: category)
        end
      end
    end
    
    redirect_to session[:form_location]
  end
    
  def edit
    @flight = Flight.find(params[:id])
    add_breadcrumb 'Flights', 'flights_path'
    add_breadcrumb "#{@flight.airline.airline_name} #{@flight.flight_number}", 'flight_path(@flight)'
    add_breadcrumb "Update Flight with New Boarding Pass", 'edit_flight_path(@flight)'
    @title = "Edit Flight"
  end
  
  def edit_with_pass
    begin
      @flight = Flight.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:warning] = "We couldnʼt find a flight with an ID of #{params[:id]}. Instead, weʼll give you a list of flights."
      redirect_to flights_path
      return
    end
    
    begin
      @pass = PKPass.find(params[:pass_id])
    rescue ActiveRecord::RecordNotFound
      flash[:warning] = "We couldnʼt find a pass with an ID of #{params[:id]}."
      redirect_to import_boarding_passes_path
      return
    end
    
    @title = "Update Flight with new Boarding Pass"
    add_breadcrumb 'Flights', 'flights_path'
    add_breadcrumb "#{@flight.airline.airline_name} #{@flight.flight_number}", 'flight_path(@flight)'
    add_breadcrumb 'Edit Flight', 'edit_flight_with_pass_path(id: @flight, pass_id: params[:pass_id])'
    
    # Build array of form fields
    fields = @pass.updated_values(@flight) || {}
    check_for_new_iata_codes(fields)
    @changed_fields = fields.reject{|k,v| v[:current_value] == v[:pass_value]}
    
    if @changed_fields.empty?
      flash[:warning] = "The updated boarding pass had no changes to make to the saved flight data."
      @pass.destroy
      redirect_to flight_path(@flight)
    end
      
  end
    
  def update
    @flight = Flight.find(params[:id])
    if @flight.update_attributes(flight_params)
      flash[:success] = "Successfully updated flight."
      if (@flight.tail_number.present? && Flight.where(:tail_number => @flight.tail_number).count > 1)
        flash[:success] += " You've had prior flights on this tail!"
      end
      if (@flight.departure_date.to_time - @flight.departure_utc.to_time).to_i.abs > 60*60*24*2
        flash[:warning] = "Your departure date and UTC time are more than a day apart &ndash; are you sure they're correct?".html_safe
      end
      @pass = PKPass.find_by(id: params[:flight][:pass_id])
      @pass.destroy if @pass
      
      redirect_to @flight
    else
      render 'edit'
    end
  end
    
  def destroy
    flight = Flight.find(params[:id])
    trip = flight.trip
    flight.destroy
    flash[:success] = "Flight destroyed."
    redirect_to trip
  end
    
  private
  
    def flight_params
      params.require(:flight).permit(:aircraft_family_id, :aircraft_name, :airline_id, :boarding_pass_data, :codeshare_airline_id, :codeshare_flight_number, :comment, :departure_date, :departure_utc, :destination_airport_id, :fleet_number, :flight_number, :operator_id, :origin_airport_id, :tail_number, :travel_class, :trip_id, :trip_section, :pass_serial_number)
    end
      
    # Accepts the output of PKPass.updated_values, and detects any airport or
    # airline IATA codes that don't already exist in the database. If there are
    # any unknown codes, it redirects to a form allowing the user to enter the codes.
    def check_for_new_iata_codes(fields)
      return nil if fields.nil?
      @undefined_codes = fields.map{|k,v| v[:lookup]}.compact.sort_by{|h| h[:type]}
      if @undefined_codes.any?
        @title = "New Flight - Undefined Fields"
        session[:form_location] = Rails.application.routes.recognize_path(request.original_url)
        render "new_undefined_fields"
      end
      return true
    end
    
    
end
