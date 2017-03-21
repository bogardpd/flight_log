Portfolio::Application.routes.draw do
  
  root "pages#flightlog"
  
  resources :users
  resources :sessions, :only => [:new, :create, :destroy]
  resources :flights, :except => [:new]
  resources :airports
  resources :airlines
  resources :aircraft_families, path: :aircraft
  resources :trips
  resources :routes, :only => [:new, :show, :create, :update]
  
  match '/signup' => 'users#new',         via: :get
  match '/login'  => 'sessions#new',      via: :get
  match '/logout' => 'sessions#destroy',  via: :delete

  get   "/flights/new/:trip_id(/:pass_id)"       => "flights#new",             as: :new_flight
  get   "/flights/from/:start_date/to/:end_date" => "flights#show_date_range", as: :show_date_range
  get   "/flights/year/:year"                    => "flights#show_date_range", as: :show_year
  
  get   "/trips/:trip/section/:section"      => "trips#show_section",          as: :show_section

  get   "/operators/:operator"               => "airlines#show_operator",      as: :show_operator
  get   "/operators/:operator/:fleet_number" => "airlines#show_fleet_number",  as: :show_fleet_number
  
  get   "/classes"                           => "flights#index_classes"
  get   "/classes/:travel_class"             => "flights#show_class",          as: :show_class
                                             
  get   "/tails"                             => "flights#index_tails"
  get   "/tails/:tail_number"                => "flights#show_tail",           as: :show_tail
  
  get   "/routes"                            => "routes#index"
  get   "/routes/edit/:airport1/:airport2"   => "routes#edit",                 as: :edit_route
  
  # Boarding pass pages:
  match '/boarding-pass'        => 'flights#input_boarding_pass', via: :get
  match '/build-boarding-pass'  => 'flights#build_boarding_pass', via: :get, as: :build_boarding_pass
  match '/boarding-pass/results/:data'  => 'flights#show_boarding_pass',  via: :get, as: :show_boarding_pass
  match '/boarding-pass/json(/:callback)/:data' => 'flights#show_boarding_pass_json',  via: :get, as:
   :show_boarding_pass_json
  match '/boarding-pass/email' => 'flights#index_emails', as: :index_emails, via: :get
  get   "/boarding-pass/import(/:trip_id)"      => "trips#import_boarding_passes", as: :import_boarding_passes
  
  # Admin pages:
  match '/admin',                         to: 'admin#admin',                   via: :get
  match '/admin/boarding-pass-validator', to: 'admin#boarding_pass_validator', via: :get, as: :boarding_pass_validator
  match '/admin/annual-summary',          to: 'admin#annual_flight_summary',   via: :get, as: :annual_flight_summary
  
  # Image proxy:
  match "/images/gcmap/:airport_options/:query/:check/map.gif" => 'pages#gcmap_image_proxy', as: :gcmap_image, via: [:get]
  
  # Certbot:
  get '/.well-known/acme-challenge/:id' => 'pages#letsencrypt'
  
end
