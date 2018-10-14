Portfolio::Application.routes.draw do
  
  root "pages#flightlog"
  
  # Users:
  resources :users
  
  # Sessions:
  resources :sessions, :only => [:new, :create, :destroy]
  get    "/signup" => "users#new"
  get    "/login"  => "sessions#new"
  delete "/logout" => "sessions#destroy"
  
  # Flights:
  get   "/flights/new-flight-menu/(trip/:trip_id)" => "flights#new_flight_menu", as: :new_flight_menu
  post  "/flights/new-flight-menu/(trip/:trip_id)" => "flights#change_trip",     as: :change_new_flight_trip
  match "/flights/new/"                            => "flights#new", via: [:get, :post], as: :new_flight
  resources :flights, :except => [:new]
  get   "/flights/from/:start_date/to/:end_date" => "flights#show_date_range",  as: :show_date_range
  get   "/flights/year/:year"                    => "flights#show_date_range",  as: :show_year
  
  # Trips:
  resources :trips
  get   "/trips/:trip/section/:section"      => "trips#show_section",           as: :show_section
  
  # Airports:
  resources :airports
          
  # Airlines and operators:                                                                      
  resources :airlines  
  get   "/operators/:operator"               => "airlines#show_operator",       as: :show_operator
  get   "/operators/:operator/:fleet_number" => "airlines#show_fleet_number",   as: :show_fleet_number
  
  # Aircraft families and types:
  get   "/aircraft/new(/family/:family_id)"    => "aircraft_families#new",      as: :new_aircraft_family
  resources :aircraft_families, path: :aircraft, except: [:new]
  
  # Travel classes:                                                     
  get   "/classes"                           => "flights#index_classes"         
  get   "/classes/:travel_class"             => "flights#show_class",           as: :show_class

  # Tail numbers:
  get   "/tails"                             => "flights#index_tails"           
  get   "/tails/:tail_number"                => "flights#show_tail",            as: :show_tail

  # Flight routes:
  resources :routes, :only => [:new, :show, :create, :update]
  get   "/routes"                            => "routes#index"                  
  get   "/routes/edit/:airport1/:airport2"   => "routes#edit",                  as: :edit_route
  
  # Boarding pass import pages:
  resources :pk_passes, :only => [:destroy]
  
  # Boarding pass parser pages:
  get   "/boarding-pass" => "flights#input_boarding_pass"
  get   "/boarding-pass/build" => "flights#build_boarding_pass", as: :build_boarding_pass
  get   "/boarding-pass/results/:data" => "flights#show_boarding_pass", as: :show_boarding_pass
  get   "/boarding-pass/json(/:callback)/:data" => "flights#show_boarding_pass_json", as:
   :show_boarding_pass_json
  
  # Admin pages:
  get   "/admin"                         => "admin#admin", as: :admin
  get   "/admin/boarding-pass-validator" => "admin#boarding_pass_validator", as: :boarding_pass_validator
  get   "/admin/annual-summary"          => "admin#annual_flight_summary",   as: :annual_flight_summary
  
  # Image proxy:
  get "/images/gcmap/:airport_options/:query/:check/map.gif" => "pages#gcmap_image_proxy", as: :gcmap_image
  
  # Certbot:
  get "/.well-known/acme-challenge/:id" => "pages#letsencrypt"
  
end
