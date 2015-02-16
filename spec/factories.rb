FactoryGirl.define do
  
  factory :user do
    name "bogardpd"
    password "foobar"
    password_confirmation "foobar"
  end
  
  factory :flight do
    origin_airport_id 1
    destination_airport_id  2
    departure_date  "2012-02-01"
    departure_utc "2012-02-01 12:00:00"
    airline "American"
    flight_number "3905"
    aircraft_family "Embraer ERJ 145"
    aircraft_variant "ERJ-145"
    tail_number "N12345"
    travel_class "Economy"
    comment "Turbulent"
    trip_section  1
  end
  
  factory :trip do
    name "Vacation Outbound"
    hidden false
    comment "foobar"
  end
  
end