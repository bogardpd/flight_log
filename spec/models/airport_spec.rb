require 'spec_helper'

describe Airport do
  
  before { @airport = Airport.new(iata_code: "ORD", city: "Chicago/O'Hare", region_conus: true) }
  
  subject { @airport }
  
  it { should respond_to(:iata_code) }
  it { should respond_to(:city) }
  it { should respond_to(:region_conus) }
  
  it { should be_valid }
  
  describe "when iata_code is not present" do
    before { @airport.iata_code = " " }
    it { should_not be_valid }
  end
  
  describe "when iata_code is too long" do
    before { @airport.iata_code = "A" * 4 }
    it { should_not be_valid }
  end
  
  describe "when iata_code is already taken" do
    before do
      airport_with_same_iata_code = @airport.dup
      airport_with_same_iata_code.iata_code = @airport.iata_code.downcase
      airport_with_same_iata_code.save
    end
   it { should_not be_valid }
  end
    
  describe "when city is not present" do
    before { @airport.city = " " }
    it { should_not be_valid }
  end
  
end
