Portfolio::Application.routes.draw do
  get "trips/new"

  get "airports/new"

  get "flights/new"

  resources :users
  resources :sessions, :only => [:new, :create, :destroy]
  resources :flights
  resources :airports
  resources :trips
  resources :routes

  root :to => 'pages#home'
  
  match '/projects', :to => 'pages#projects'
  match '/resume', :to => 'pages#resume'
  match '/about', :to => 'pages#about'
  match '/other', :to => 'pages#other'
  
  match '/signup', :to => 'users#new'
  match '/login', :to => 'sessions#new'
  match '/logout', :to => 'sessions#destroy', :via => :delete
  
  match '/computers', :to => 'pages#computers'
  match '/computer_history', :to => 'pages#computer_history'
  match '/cooking', :to => 'pages#cooking'
  match '/current_home', :to => 'pages#current_home'
  match '/ebdb', :to => 'pages#ebdb'
  match '/flight_log', :to => 'pages#flight_log'
  match '/gps_log', :to => 'pages#gps_log'
  match '/gps_logging_garmin', :to => 'pages#gps_logging_garmin'
  match '/gps_logging_iphone', :to => 'pages#gps_logging_iphone'
  match '/hotel_internet_quality', :to => 'pages#hotel_internet_quality'
  match '/itinerary/', :to => 'pages#itinerary'
  match '/modeling/', :to => 'pages#modeling'
  match '/stephenvlog/', :to => 'pages#stephenvlog'
  match '/tulsa_penguins', :to => 'pages#tulsa_penguins'
  match '/turn_signal_counter', :to => 'pages#turn_signal_counter'
  match '/visor_cam', :to => 'pages#visor_cam'
  
  match '/pax_prime_2012', :to => 'pages#pax_prime_2012'
  
  match '/flightlog', :to => 'pages#flightlog'
  match '/flightlog/:region', :to => 'pages#flightlog', :as => :show_flightlog_region
  match '/flights/sort/:sort_category/:sort_direction' => 'flights#index', :as => :sort_flights
  match '/flights/from/:start_date/to/:end_date', :to => 'flights#show_date_range', :as => :show_date_range
  match '/flights/from/:start_date/to/:end_date/:region', :to => 'flights#show_date_range', :as => :show_date_range_region
  match '/flights/year/:year', :to => 'flights#show_date_range', :as => :show_year
  match '/flights/year/:year/:region', :to => 'flights#show_date_range', :as => :show_year_region
  match '/trips/:trip/section/:section' => 'trips#show_section', :as => :show_section
  match '/aircraft' => 'flights#index_aircraft'
  match '/aircraft/sort/:sort_category/:sort_direction' => 'flights#index_aircraft', :as => :sort_aircraft
  match '/aircraft/:aircraft_family' => 'flights#show_aircraft', :as => :show_aircraft
  match '/airlines' => 'flights#index_airlines'
  match '/airlines/sort/:sort_category/:sort_direction' => 'flights#index_airlines', :as => :sort_airlines
  match '/airlines/:airline' => 'flights#show_airline', :as => :show_airline
  match '/airports/sort/:sort_category/:sort_direction' => 'airports#index', :as => :sort_airports
  match '/airports/:id/sort/:sort_category/:sort_direction' => 'airports#show', :as => :sort_airport
  match '/operators/:operator' => 'flights#show_operator', :as => :show_operator
  match '/operators/:operator/:fleet_number' => 'flights#show_fleet_number', :as => :show_fleet_number
  match '/classes' => 'flights#index_classes'
  match '/classes/:travel_class' => 'flights#show_class', :as => :show_class
  match '/tails' => 'flights#index_tails'
  match '/tails/sort/:sort_category/:sort_direction' => 'flights#index_tails', :as => :sort_tails
  match '/tails/:tail_number' => 'flights#show_tail', :as => :show_tail
  match '/routes/edit/:airport1/:airport2' => 'routes#edit', :as => :edit_route
  match '/routes/sort/:sort_category/:sort_direction' => 'routes#index', :as => :sort_routes
  match '/trips/sort/:sort_category/:sort_direction' => 'trips#index', :as => :sort_trips
end
