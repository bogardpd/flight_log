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
    
  match '/signup', :to => 'users#new', :via => [:get]
  match '/login', :to => 'sessions#new', :via => [:get]
  match '/logout', :to => 'sessions#destroy', :via => :delete
  
  match '/annual_summary', to: 'flights#show_annual_summary', via: [:get]

  match '/flights/from/:start_date/to/:end_date', :to => 'flights#show_date_range', :as => :show_date_range, :via => [:get]
  match '/flights/year/:year', :to => 'flights#show_date_range', :as => :show_year, :via => [:get]
  
  match '/trips/:trip/section/:section' => 'trips#show_section', :as => :show_section, :via => [:get]

  match '/operators/:operator' => 'airlines#show_operator', as: :show_operator, via: [:get]
  match '/operators/:operator/:fleet_number' => 'airlines#show_fleet_number', as: :show_fleet_number, via: [:get]
  
  match '/classes' => 'flights#index_classes', :via => [:get]
  match '/classes/:travel_class' => 'flights#show_class', :as => :show_class, :via => [:get]
  
  match '/tails' => 'flights#index_tails', :via => [:get]
  match '/tails/:tail_number' => 'flights#show_tail', :as => :show_tail, :via => [:get]
  
  match '/routes' => 'routes#index', via: :get
  match '/routes/edit/:airport1/:airport2' => 'routes#edit', as: :edit_route, via: :get
  
  # Image proxy:
  match "/images/gcmap/:airport_options/:query/:check/map.gif" => 'pages#gcmap_image_proxy', as: :gcmap_image, via: [:get]
  
  # Certbot:
  get '/.well-known/acme-challenge/:id' => 'pages#letsencrypt'
  
end
