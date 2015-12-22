Portfolio::Application.routes.draw do
  get "trips/new"

  get "airports/new"

  get "flights/new"

  resources :users
  resources :sessions, :only => [:new, :create, :destroy]
  resources :flights
  resources :airports
  resources :trips
  resources :routes, :only => [:new, :create, :update]

  root 'pages#flightlog'
  
  match '/signup', :to => 'users#new', :via => [:get]
  match '/login', :to => 'sessions#new', :via => [:get]
  match '/logout', :to => 'sessions#destroy', :via => :delete

  
 # match '/flightlog', :to => 'pages#flightlog', :via => [:get]
  match '/:region', :to => 'pages#flightlog', :as => :show_flightlog_region, :via => [:get]
  match '/flights/sort/:sort_category/:sort_direction' => 'flights#index', :as => :sort_flights, :via => [:get]
  match '/flights/from/:start_date/to/:end_date', :to => 'flights#show_date_range', :as => :show_date_range, :via => [:get]
  match '/flights/from/:start_date/to/:end_date/:region', :to => 'flights#show_date_range', :as => :show_date_range_region, :via => [:get]
  match '/flights/year/:year', :to => 'flights#show_date_range', :as => :show_year, :via => [:get]
  match '/flights/year/:year/:region', :to => 'flights#show_date_range', :as => :show_year_region, :via => [:get]
  match '/trips/:trip/section/:section' => 'trips#show_section', :as => :show_section, :via => [:get]
  match '/aircraft' => 'flights#index_aircraft', :via => [:get]
  match '/aircraft/sort/:sort_category/:sort_direction' => 'flights#index_aircraft', :as => :sort_aircraft, :via => [:get]
  match '/aircraft/:aircraft_family' => 'flights#show_aircraft', :as => :show_aircraft, :via => [:get]
  match '/airlines' => 'flights#index_airlines', :via => [:get]
  match '/airlines/sort/:sort_category/:sort_direction' => 'flights#index_airlines', :as => :sort_airlines, :via => [:get]
  match '/airlines/:airline' => 'flights#show_airline', :as => :show_airline, :via => [:get]
  match '/airports/sort/:sort_category/:sort_direction' => 'airports#index', :as => :sort_airports, :via => [:get]
  match '/airports/:id/sort/:sort_category/:sort_direction' => 'airports#show', :as => :sort_airport, :via => [:get]
  match '/operators/:operator' => 'flights#show_operator', :as => :show_operator, :via => [:get]
  match '/operators/:operator/:fleet_number' => 'flights#show_fleet_number', :as => :show_fleet_number, :via => [:get]
  match '/classes' => 'flights#index_classes', :via => [:get]
  match '/classes/:travel_class' => 'flights#show_class', :as => :show_class, :via => [:get]
  match '/tails' => 'flights#index_tails', :via => [:get]
  match '/tails/sort/:sort_category/:sort_direction' => 'flights#index_tails', :as => :sort_tails, :via => [:get]
  match '/tails/:tail_number' => 'flights#show_tail', :as => :show_tail, :via => [:get]
  match '/routes/edit/:airport1/:airport2' => 'routes#edit', :as => :edit_route, :via => [:get]
  match '/routes/sort/:sort_category/:sort_direction' => 'routes#index', :as => :sort_routes, :via => [:get]
  match '/trips/sort/:sort_category/:sort_direction' => 'trips#index', :as => :sort_trips, :via => [:get]
end
