Portfolio::Application.routes.draw do
  
  root "pages#flightlog"
  
  # Resources:
  resources :users
  resources :sessions, :only => [:new, :create, :destroy]
  resources :flights, :except => [:new]
  resources :airports
  resources :airlines
  resources :aircraft_families, path: :aircraft
  resources :trips
  resources :routes, :only => [:new, :show, :create, :update]
  resources :pk_passes, :only => [:destroy]
  
  # Sessions:
  get    "/signup" => "users#new"
  get    "/login"  => "sessions#new"
  delete "/logout" => "sessions#destroy"
  
  # Flights:
  get   "/flights/new/trip/:trip_id(/pass/:pass_id)" => "flights#new",          as: :new_flight
  get   "/flights/:id/edit/pass/:pass_id"        => "flights#edit_with_pass",   as: :edit_flight_with_pass
  post  "/flights/create-iata-icao/"             => "flights#create_iata_icao", as: :create_iata_icao
  get   "/flights/from/:start_date/to/:end_date" => "flights#show_date_range",  as: :show_date_range
  get   "/flights/year/:year"                    => "flights#show_date_range",  as: :show_year
  
  # Trips:
  get   "/trips/:trip/section/:section"      => "trips#show_section",           as: :show_section
          
  # Airlines and operators:                                                                      
  get   "/operators/:operator"               => "airlines#show_operator",       as: :show_operator
  get   "/operators/:operator/:fleet_number" => "airlines#show_fleet_number",   as: :show_fleet_number
  
  # Travel classes:                                                     
  get   "/classes"                           => "flights#index_classes"         
  get   "/classes/:travel_class"             => "flights#show_class",           as: :show_class

  # Tail numbers:
  get   "/tails"                             => "flights#index_tails"           
  get   "/tails/:tail_number"                => "flights#show_tail",            as: :show_tail

  # Routes:
  get   "/routes"                            => "routes#index"                  
  get   "/routes/edit/:airport1/:airport2"   => "routes#edit",                  as: :edit_route
  
  # Boarding pass parser pages:
  get   "/boarding-pass" => "flights#input_boarding_pass"
  get   "/boarding-pass/build" => "flights#build_boarding_pass", as: :build_boarding_pass
  get   "/boarding-pass/results/:data" => "flights#show_boarding_pass", as: :show_boarding_pass
  get   "/boarding-pass/json(/:callback)/:data" => "flights#show_boarding_pass_json", as:
   :show_boarding_pass_json
  
  # Boarding pass input pages:
  get   "/boarding-pass/import(/trip/:trip_id)" => "pk_passes#index",        as: :import_boarding_passes
  post  "/boarding-pass/import(/trip/:trip_id)" => "pk_passes#change_trip",  as: :change_boarding_pass_trip
  
  # Admin pages:
  get   "/admin"                         => "admin#admin"
  get   "/admin/boarding-pass-validator" => "admin#boarding_pass_validator", as: :boarding_pass_validator
  get   "/admin/annual-summary"          => "admin#annual_flight_summary",   as: :annual_flight_summary
  
  # Image proxy:
  get "/images/gcmap/:airport_options/:query/:check/map.gif" => "pages#gcmap_image_proxy", as: :gcmap_image
  
  # Certbot:
  get "/.well-known/acme-challenge/:id" => "pages#letsencrypt"
  
end
