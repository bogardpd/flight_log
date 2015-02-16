require 'spec_helper'

describe Trip do
  
  before { @trip = Trip.new(name: "Vacation Outbound", hidden: false, comment: "foobar") }
  
  subject { @trip }
  
  it { should respond_to(:name) }
  it { should respond_to(:hidden) }
  it { should respond_to(:comment) }
  it { should respond_to(:flights) }
  
  it { should be_valid }
  
  describe "when name is not present" do
    before { @trip.name = " " }
    it { should_not be_valid }
  end
  
  describe "flight associations" do
    
    before { @trip.save }
    let!(:sample_trip) do
      FactoryGirl.create(:flight, trip: @trip)
    end
    
    it "should destroy associated flights" do
      flights = @trip.flights.dup
      @trip.destroy
      flights.should_not be_empty
      flights.each do |flight|
        Flight.find_by_id(flight.id).should be_nil
      end
    end
  
  end
  
end
