Portfolio::Application.routes.draw do
  get "trips/new"
  get "airports/new"
  get "flights/new"

  resources :users
  resources :sessions, :only => [:new, :create, :destroy]
  resources :flights
  resources :airports
  resources :airlines
  resources :aircraft_families, path: :aircraft
  resources :trips
  resources :routes, :only => [:new, :show, :create, :update]
  
  root 'pages#flightlog'
    
  match '/signup' => 'users#new',         via: :get
  match '/login'  => 'sessions#new',      via: :get
  match '/logout' => 'sessions#destroy',  via: :delete

  match '/flights/from/:start_date/to/:end_date', :to => 'flights#show_date_range', :as => :show_date_range, :via => [:get]
  match '/flights/year/:year', :to => 'flights#show_date_range', :as => :show_year, :via => [:get]
  
  match '/trips/:trip/section/:section' => 'trips#show_section', :as => :show_section, :via => [:get]

  match '/operators/:operator'                => 'airlines#show_operator',      via: :get, as: :show_operator
  match '/operators/:operator/:fleet_number'  => 'airlines#show_fleet_number',  via: :get, as: :show_fleet_number
  
  match '/classes'                => 'flights#index_classes', via: :get
  match '/classes/:travel_class'  => 'flights#show_class',    via: :get, as: :show_class
  
  match '/tails'              => 'flights#index_tails', via: :get
  match '/tails/:tail_number' => 'flights#show_tail',   via: :get, as: :show_tail
  
  match '/routes'                           => 'routes#index',  via: :get
  match '/routes/edit/:airport1/:airport2'  => 'routes#edit',   via: :get, as: :edit_route
  
  match '/boarding-pass'        => 'flights#input_boarding_pass', via: :get
  match '/build-boarding-pass'  => 'flights#build_boarding_pass', via: :get, as: :build_boarding_pass
  match '/boarding-pass/results/:data'  => 'flights#show_boarding_pass',  via: :get, as: :show_boarding_pass
  match '/boarding-pass/json(/:callback)/:data'  => 'flights#show_boarding_pass_json',  via: :get, as: :show_boarding_pass_json
  
  # Admin pages:
  match '/admin',                         to: 'admin#admin',                   via: :get
  match '/admin/boarding-pass-validator', to: 'admin#boarding_pass_validator', via: :get, as: :boarding_pass_validator
  match '/admin/annual-summary',          to: 'admin#annual_flight_summary',   via: :get, as: :annual_flight_summary
  
  # Image proxy:
  match "/images/gcmap/:airport_options/:query/:check/map.gif" => 'pages#gcmap_image_proxy', as: :gcmap_image, via: [:get]
  
  # Certbot:
  get '/.well-known/acme-challenge/:id' => 'pages#letsencrypt'
  
end
