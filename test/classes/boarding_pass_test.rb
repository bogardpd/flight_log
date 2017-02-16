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
  
  class BoardingPassGeneralTest < BoardingPassTest
    test "boarding pass with field split by end of group" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 BOSJFKB6 0717 345P014C0010 147>3180 M6344BB6              21279          0 B6 B6 1234567890          ^160MEUCICFMA7Cl4KV626AIdavAb/AS2+OmCesErB0giiK5E9xMAiEAkzmMderGbB7hrPG7JP6zAh4LbFRNCH4E4xG91c/ymaM=")
      # Unknown field should be populated:
      assert_equal("1234567890  ", pass.data.dig(:repeated, 0, :conditional, 0, :raw))
      # Baggage Tag field should be nil:
      refute_nil pass.data
    end
    
    test "boarding pass with extra group data after fields" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 DAYCLTAA 5163 346Y015D0027 150>21A MM5346BAA              yy2F001001123456732AA AA XXXXXXX          0PCzzzzzzX")
      assert_equal("yy", pass.data.dig(:unique, :conditional, 0, :raw))
      assert_equal("zzzzzz", pass.data.dig(:repeated, 0, :conditional, 0, :raw))
    end
    
    test "boarding pass with all valid fields is valid" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 BOSJFKB6 0717 345P014C0010 147>3180 M6344BB6              29279          0 B6 B6 1234567890          ^108abcdefgh")
      assert_equal(true, pass.is_valid?)
    end
    
    test "boarding pass with unknown field is not valid" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 BOSJFKB6 0717 345P014C0010 147>3180 M6344BB6              29279          0 B6 B6 1234567890          ^108abcdefgh ")
      assert_equal(false, pass.is_valid?)
    end
    
    test "boarding pass with invalid field is not valid" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 B1SJFKB6 0717 345P014C0010 147>3180 M6344BB6              29279          0 B6 B6 1234567890          ^108abcdefgh")
      assert_equal(false, pass.is_valid?)
    end
    
  end
  
  class BoardingPassControlTest < BoardingPassTest
    test "boarding pass with invalid leg field" do
      pass_text = "MZDOE/JOHN            EABC123 BOSJFKB6 0717 345P014C0010 147>3180 M6344BB6              29279          0 B6 B6 1234567890          ^160MEUCICFMA7Cl4KV626AIdavAb/AS2+OmCesErB0giiK5E9xMAiEAkzmMderGbB7hrPG7JP6zAh4LbFRNCH4E4xG91c/ymaM="
      pass = BoardingPass.new(pass_text)
      assert_equal(pass_text, pass.data.dig(:unknown, 0, :raw))
    end
    
    test "boarding pass shorter than mandatory length" do
      pass_text = "M1DOE/JOHN            EABC123 BOSJFKB6 0717 345P014C0010 14"
      pass = BoardingPass.new(pass_text)
      assert_equal(pass_text, pass.data.dig(:unknown, 0, :raw))
    end
    
    test "boarding pass with invalid hex in rm0" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 BOSJFKB6 0717 345P014C0010 1ZZ>3180 M6344BB6              29279          0 B6 B6 1234567890          ^160MEUCICFMA7Cl4KV626AIdavAb/AS2+OmCesErB0giiK5E9xMAiEAkzmMderGbB7hrPG7JP6zAh4LbFRNCH4E4xG91c/ymaM=")
      assert_equal(false, pass.data.dig(:repeated, 0, :mandatory, 6, :valid))
      assert_equal(">3180 M6344BB6              29279          0 B6 B6 1234567890          ^160MEUCICFMA7Cl4KV626AIdavAb/AS2+OmCesErB0giiK5E9xMAiEAkzmMderGbB7hrPG7JP6zAh4LbFRNCH4E4xG91c/ymaM=", pass.data.dig(:unknown, 0, :raw))
    end
    
    test "boarding pass with invalid hex in rc0" do
      pass = BoardingPass.new("M2DOE/JOHN            EABC123 DAYORDAA 1234 123Y001A0001 14C>3181WW6122BAA 00011234560012G0141234567890 1AA AA 1234567890123    1PCABCDEDEF456 ORDSEAAA 5678 123Y002A0002 12D290011234567891 1AA AA 1234567890       1PCFG^164BJ50O43F9LVV9ZZNMUJR54172ML8XHESJO5K1CQ4NGTP3UMXCTYDQP2E763HH58CMA4PP2VJA8N19XPL7T0134QLG5L4OJWFK6H9")
      assert_equal(false, pass.data.dig(:repeated, 0, :conditional, 17, :valid))
      assert_equal("0141234567890 1AA AA 1234567890123    1PCABCDEDEF456 ORDSEAAA 5678 123Y002A0002 12D290011234567891 1AA AA 1234567890       1PCFG^164BJ50O43F9LVV9ZZNMUJR54172ML8XHESJO5K1CQ4NGTP3UMXCTYDQP2E763HH58CMA4PP2VJA8N19XPL7T0134QLG5L4OJWFK6H9", pass.data.dig(:unknown, 0, :raw))
    end
    
    test "boarding pass with no version bracket" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 BOSJFKB6 0717 345P014C0010 147x3180 M6344BB6              29279          0 B6 B6 1234567890          ^108abcdefgh")
      assert_nil(pass.data.dig(:unique, :security))
      assert_equal("x3180 M6344BB6              29279          0 B6 B6 1234567890          ^108abcdefgh", pass.data.dig(:unknown, 0, :raw))
    end
    
    test "boarding pass with version bracket too early" do
      pass = BoardingPass.new("M1DOE/JOHN>2          EABC123 BOSJFKB6 0717 345P014C0010 147>3180 M6344BB6              29279          0 B6 B6 1234567890          ^108abcdefgh")
      assert_nil(pass.data.dig(:unique, :security))
      assert_equal(">3180 M6344BB6              29279          0 B6 B6 1234567890          ^108abcdefgh", pass.data.dig(:unknown, 0, :raw))
    end
    
    test "boarding pass with no airline data" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 BOSJFKB6 0717 345P014C0010 147>3180 M6344BB6              29279          0 B6 B6 1234567890          ^160MEUCICFMA7Cl4KV626AIdavAb/AS2+OmCesErB0giiK5E9xMAiEAkzmMderGbB7hrPG7JP6zAh4LbFRNCH4E4xG91c/ymaM=")
      assert_nil(pass.data.dig(:repeated, 0, :airline))
    end
    
    test "boarding pass with no caret" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 BOSJFKB6 0717 345P014C0010 147>3180 M6344BB6              29279          0 B6 B6 1234567890          108abcdefgh")
      assert_nil(pass.data.dig(:unique, :security))
      assert_equal("108abcdefgh", pass.data.dig(:unknown, 0, :raw))
    end
    
    test "boarding pass with first caret too early" do
      pass = BoardingPass.new("M1DOE/JOHN^           EABC123 BOSJFKB6 0717 345P014C0010 147>3180 M6344BB6              29279          0 B6 B6 1234567890          ^108abcdefgh")
      assert_nil(pass.data.dig(:unique, :security))
      assert_equal("^108abcdefgh", pass.data.dig(:unknown, 0, :raw))
    end
    
    test "boarding pass with first caret too late" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 BOSJFKB6 0717 345P014C0010 147>3180 M6344BB6              29279          0 B6 B6 1234567890           ^108abcdefgh")
      assert_nil(pass.data.dig(:unique, :security))
      assert_equal(" ^108abcdefgh", pass.data.dig(:unknown, 0, :raw))
    end
    
    test "boarding pass with extra data after security" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 BOSJFKB6 0717 345P014C0010 147>3180 M6344BB6              29279          0 B6 B6 1234567890          ^108abcdefghij")
      assert_equal("ij", pass.data.dig(:unknown, 0, :raw))
    end
    
    test "boarding pass where not enough security data exists" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 BOSJFKB6 0717 345P014C0010 147>3180 M6344BB6              29279          0 B6 B6 1234567890          ^108abcdef")
      assert_equal("abcdef", pass.data.dig(:unknown, 0, :raw))
    end
  end
  
  class BoardingPassOrdinalTest < BoardingPassTest
    
    test "ordinal flight with blank flight date" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 DAYCLTAA 5163    Y015D0027 148>218 MM    BAA              29001001123456732AA AA XXXXXXX             X")
      interpreted = pass.data.dig(:repeated, 0, :mandatory, 46, :interpretation)
      assert_nil interpreted
    end
    
    test "ordinal flight with non-numeric flight date" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 DAYCLTAA 5163 ZZZY015D0027 148>218 MM    BAA              29001001123456732AA AA XXXXXXX             X")
      interpreted = pass.data.dig(:repeated, 0, :mandatory, 46, :interpretation)
      assert_nil interpreted
    end
    
    test "ordinal flight date without issue date" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 DAYCLTAA 5163 346Y015D0027 148>218 MM    BAA              29001001123456732AA AA XXXXXXX             X")
      interpreted = pass.data.dig(:repeated, 0, :mandatory, 46, :interpretation)
      # Should return this ordinal date for last year, this year, and next year:
      assert_equal("346th day of the year (12 Dec 2015, 11 Dec 2016, 12 Dec 2017)", interpreted)
    end
  
    test "ordinal flight date of 366 without issue date" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 DAYCLTAA 5163 366Y015D0027 148>218 MM    BAA              29001001123456732AA AA XXXXXXX             X")
      interpreted = pass.data.dig(:repeated, 0, :mandatory, 46, :interpretation)
      # Should return most recent valid ordinal date on or prior to today:
      assert_equal("366th day of the year (31 Dec 2016)", interpreted)
    end
  
    test "ordinal flight date with issue date" do
      # Deliberately set the pass date in a year before a leap year, as this
      # could cause two results in pass_date...pass_date+1.year, and we only
      # want one
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 DAYCLTAA 5163 346Y015D0027 148>218 MM5346BAA              29001001123456732AA AA XXXXXXX             X")
      interpreted = pass.data.dig(:repeated, 0, :mandatory, 46, :interpretation)
      # Should return first valid ordinal date on or after the boarding pass issue date:
      assert_equal("346th day of the year (12 Dec 2015)", interpreted)
    end
    
    test "ordinal flight date with @flight available" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 DAYCLTAA 5163 346Y015D0027 148>218 MM5346BAA              29001001123456732AA AA XXXXXXX             X", flight: @flight)
      interpreted = pass.data.dig(:repeated, 0, :mandatory, 46, :interpretation)
      # Test should prioritize @flight over boarding pass date, so we should
      # get 2014 even though the boarding pass issue date is 2015.
      # Should return ordinal date in the year of @flight's departure date:
      assert_equal("346th day of the year (12 Dec 2014)", interpreted)
    end
    
    test "ordinal flight date greater than 366" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 DAYCLTAA 5163 367Y015D0027 148>218 MM    BAA              29001001123456732AA AA XXXXXXX             X")
      interpreted = pass.data.dig(:repeated, 0, :mandatory, 46, :interpretation)
      # Should return nil
      assert_nil interpreted
    end
    
    test "ordinal pass date with blank pass date" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 DAYCLTAA 5163 346Y015D0027 148>218 MM    BAA              29001001123456732AA AA XXXXXXX             X")
      interpreted = pass.data.dig(:unique, :conditional, 22, :interpretation)
      assert_nil interpreted
    end
    
    test "ordinal pass date with non-numeric pass date" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 DAYCLTAA 5163 346Y015D0027 148>218 MMZZZZBAA              29001001123456732AA AA XXXXXXX             X")
      interpreted = pass.data.dig(:unique, :conditional, 22, :interpretation)
      assert_nil interpreted
    end
    
    test "ordinal pass date with @flight available" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 DAYCLTAA 5163 346Y015D0027 148>218 MM5345BAA              29001001123456732AA AA XXXXXXX             X", flight: @flight)
      interpreted = pass.data.dig(:unique, :conditional, 22, :interpretation)
      # Should return most recent matching date on or before @flight's departure date:
      assert_equal("345th day of a year ending in 5 (11 Dec 2005)", interpreted)
    end
    
    test "ordinal pass date without @flight available" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 DAYCLTAA 5163 346Y015D0027 148>218 MM5345BAA              29001001123456732AA AA XXXXXXX             X")
      interpreted = pass.data.dig(:unique, :conditional, 22, :interpretation)
      # Issue date should not be in the future
      # Should return most recent matching date on or before today:
      assert_equal("345th day of a year ending in 5 (11 Dec 2015)", interpreted)
    end
    
    test "ordinal pass date greater than 366" do
      pass = BoardingPass.new("M1DOE/JOHN            EABC123 DAYCLTAA 5163 346Y015D0027 148>218 MM5367BAA              29001001123456732AA AA XXXXXXX             X")
      interpreted = pass.data.dig(:unique, :conditional, 22, :interpretation)
      # Should return nil
      assert_nil interpreted
    end
    
  end
  
  
  
end
