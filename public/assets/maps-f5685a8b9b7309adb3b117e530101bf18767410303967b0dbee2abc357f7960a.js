mapboxgl.accessToken = '<%= Rails.env.development? ? Rails.application.credentials[:mapbox][:api_key][:unrestricted] : Rails.application.credentials[:mapbox][:api_key][:flight_historian] %>';
