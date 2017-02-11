require 'test_helper'

class BoardingPassTest < ActiveSupport::TestCase
  
  def setup
    # Make all tests assume that it is 10 Jan 2017 at noon local:
    travel_to Time.new(2017, 1, 10, 12)
    
    trip = Trip.new( name: "Public Trip",
                           hidden:  false,
                           purpose: "personal")
    
    @flight = trip.flights.new(origin_airport_id:      1,
                               destination_airport_id: 2,
                               trip_section:           1,
                               departure_date:         "2014-12-12",
                               departure_utc:          "2014-12-12 11:00",
                               airline_id:             1)
  end
  
  def get_field_value(boarding_pass, description)
    interpreted = nil
    boarding_pass.raw_with_metadata.each do |field|
      if field[:description] == description
        interpreted = field[:interpreted]
        break
      end
    end
    return interpreted
  end
  
  class BoardingPassGeneralTest < BoardingPassTest
    test "boarding pass with field split by end of group" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 DAYCLTAA 5163 346Y015D0027 147>217 MM5346BAA 11234567890029001001123456732AA AA XXXXXXX             X")
      # Unknown field should be populated:
      assert_equal("112345678900", pass.data.dig(:unique, :conditional, 0, :raw))
      # Baggage Tag field should be nil:
      refute_nil pass.data
    end
    
    test "boarding pass with extra group data after fields" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 DAYCLTAA 5163 346Y015D0027 150>21A MM5346BAA              yy2F001001123456732AA AA XXXXXXX          0PCzzzzzzX")
      assert_equal("yy", pass.data.dig(:unique, :conditional, 0, :raw))
      assert_equal("zzzzzz", pass.data.dig(:repeated, 0, :conditional, 0, :raw))
    end
  end
  
  class BoardingPassControlTest < BoardingPassTest
    test "boarding pass with no airline data" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 BOSJFKB6 0717 345P014C0010 147>3180 M6344BB6              29279          0 B6 B6 1234567890          ^160MEUCICFMA7Cl4KV626AIdavAb/AS2+OmCesErB0giiK5E9xMAiEAkzmMderGbB7hrPG7JP6zAh4LbFRNCH4E4xG91c/ymaM=")
      assert_nil(pass.data.dig(:repeated, 0, :airline))
    end
  end
  
  class BoardingPassOrdinalTest < BoardingPassTest
    
    test "ordinal flight with blank flight date" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 DAYCLTAA 5163    Y015D0027 148>218 MM    BAA              29001001123456732AA AA XXXXXXX             X")
      interpreted = get_field_value(pass, "[Leg 1] Date of Flight (Julian Date)")
      assert_nil interpreted
    end
    
    test "ordinal flight with non-numeric flight date" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 DAYCLTAA 5163 ZZZY015D0027 148>218 MM    BAA              29001001123456732AA AA XXXXXXX             X")
      interpreted = get_field_value(pass, "[Leg 1] Date of Flight (Julian Date)")
      assert_nil interpreted
    end
    
    test "ordinal flight date without issue date" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 DAYCLTAA 5163 346Y015D0027 148>218 MM    BAA              29001001123456732AA AA XXXXXXX             X")
      interpreted = get_field_value(pass, "[Leg 1] Date of Flight (Julian Date)")
      # Should return this ordinal date for last year, this year, and next year:
      assert_equal("346th day of the year (12 Dec 2015, 11 Dec 2016, 12 Dec 2017)", interpreted)
    end
  
    test "ordinal flight date of 366 without issue date" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 DAYCLTAA 5163 366Y015D0027 148>218 MM    BAA              29001001123456732AA AA XXXXXXX             X")
      interpreted = get_field_value(pass, "[Leg 1] Date of Flight (Julian Date)")
      # Should return most recent valid ordinal date on or prior to today:
      assert_equal("366th day of the year (31 Dec 2016)", interpreted)
    end
  
    test "ordinal flight date with issue date" do
      # Deliberately set the pass date in a year before a leap year, as this
      # could cause two results in pass_date...pass_date+1.year, and we only
      # want one
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 DAYCLTAA 5163 346Y015D0027 148>218 MM5346BAA              29001001123456732AA AA XXXXXXX             X")
      interpreted = get_field_value(pass, "[Leg 1] Date of Flight (Julian Date)")
      # Should return first valid ordinal date on or after the boarding pass issue date:
      assert_equal("346th day of the year (12 Dec 2015)", interpreted)
    end
    
    test "ordinal flight date with @flight available" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 DAYCLTAA 5163 346Y015D0027 148>218 MM5346BAA              29001001123456732AA AA XXXXXXX             X", flight: @flight)
      interpreted = get_field_value(pass, "[Leg 1] Date of Flight (Julian Date)")
      # Test should prioritize @flight over boarding pass date, so we should
      # get 2014 even though the boarding pass issue date is 2015.
      # Should return ordinal date in the year of @flight's departure date:
      assert_equal("346th day of the year (12 Dec 2014)", interpreted)
    end
    
    test "ordinal flight date greater than 366" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 DAYCLTAA 5163 367Y015D0027 148>218 MM    BAA              29001001123456732AA AA XXXXXXX             X")
      interpreted = get_field_value(pass, "[Leg 1] Date of Flight (Julian Date)")
      # Should return nil
      assert_equal("367th day of the year (not a valid date)", interpreted)
    end
    
    test "ordinal pass date with blank pass date" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 DAYCLTAA 5163 346Y015D0027 148>218 MM    BAA              29001001123456732AA AA XXXXXXX             X")
      interpreted = get_field_value(pass, "Date of Issue of Boarding Pass (Julian Date)")
      assert_nil interpreted
    end
    
    test "ordinal pass date with non-numeric pass date" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 DAYCLTAA 5163 346Y015D0027 148>218 MMZZZZBAA              29001001123456732AA AA XXXXXXX             X")
      interpreted = get_field_value(pass, "Date of Issue of Boarding Pass (Julian Date)")
      assert_nil interpreted
    end
    
    test "ordinal pass date with @flight available" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 DAYCLTAA 5163 346Y015D0027 148>218 MM5345BAA              29001001123456732AA AA XXXXXXX             X", flight: @flight)
      interpreted = get_field_value(pass, "Date of Issue of Boarding Pass (Julian Date)")
      # Should return most recent matching date on or before @flight's departure date:
      assert_equal("345th day of a year ending in 5 (11 Dec 2005)", interpreted)
    end
    
    test "ordinal pass date without @flight available" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 DAYCLTAA 5163 346Y015D0027 148>218 MM5345BAA              29001001123456732AA AA XXXXXXX             X")
      interpreted = get_field_value(pass, "Date of Issue of Boarding Pass (Julian Date)")
      # Issue date should not be in the future
      # Should return most recent matching date on or before today:
      assert_equal("345th day of a year ending in 5 (11 Dec 2015)", interpreted)
    end
    
    test "ordinal pass date greater than 366" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 DAYCLTAA 5163 346Y015D0027 148>218 MM5367BAA              29001001123456732AA AA XXXXXXX             X")
      interpreted = get_field_value(pass, "Date of Issue of Boarding Pass (Julian Date)")
      # Issue date should not be in the future
      # Should return most recent matching date on or before today:
      assert_equal("367th day of a year ending in 5 (not a valid date)", interpreted)
    end
    
  end
  
  
  
end
