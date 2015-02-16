require 'spec_helper'

describe Flight do
  
  let(:trip) { FactoryGirl.create(:trip) }
  before { @flight = trip.flights.build(origin_airport_id: 1, destination_airport_id: 2, trip_section: 1, departure_date: "2012-02-05", departure_utc: "2012-02-05 12:00:00", airline: "Oceanic", flight_number: 815, aircraft_family: "Boeing 747", aircraft_variant: "747-800", tail_number: "N12345", travel_class: "First", comment: "Lost")}
  
  subject { @flight }
  
  it { should respond_to(:origin_airport_id) }
  it { should respond_to(:destination_airport_id) }
  it { should respond_to(:trip_id) }
  it { should respond_to(:trip_section) }
  it { should respond_to(:departure_date) }
  it { should respond_to(:departure_utc) }
  it { should respond_to(:airline) }
  it { should respond_to(:flight_number) }
  it { should respond_to(:aircraft_family) }
  it { should respond_to(:aircraft_variant) }
  it { should respond_to(:tail_number) }
  it { should respond_to(:travel_class) }
  it { should respond_to(:comment) }
  
  it { should respond_to(:trip) }
  it { should respond_to(:origin_airport) }
  it { should respond_to(:destination_airport) }
  its(:trip) { should == trip }
  
  it { should be_valid }
  
  describe "when origin_airport_id is not present" do
    before { @flight.origin_airport_id = " " }
    it { should_not be_valid }
  end

  describe "when destination_airport_id is not present" do
    before { @flight.destination_airport_id = " " }
    it { should_not be_valid }
  end
    
  describe "when trip_id is not present" do
    before { @flight.trip_id = nil }
    it { should_not be_valid }
  end
    
  describe "when trip_section is not present" do
    before { @flight.trip_section = " " }
    it { should_not be_valid }
  end
    
  describe "when departure_date is not present" do
    before { @flight.departure_date = " " }
    it { should_not be_valid }
  end
  
  describe "when departure_date is not present" do
    before { @flight.departure_utc = " " }
    it { should_not be_valid }
  end
  
end
