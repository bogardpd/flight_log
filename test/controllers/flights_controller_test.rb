require "test_helper"

class FlightsControllerTest < ActionDispatch::IntegrationTest
  
  def test_index_flights_success
    get flights_path
    assert_response :success
  end

  def test_show_flight_success
    flight = flights(:flightORDDFW)
    get flight_path(flight)
    assert_response :success
  end
  
  def test_show_year_success
    get show_year_path(2015)
    assert_response :success
  end
  
  def test_show_date_range_success
    get show_date_range_path(start_date: "2014-07-01", end_date: "2015-06-30")
    assert_response :success
  end

  def test_show_date_range_with_leading_zero_success
    # Leading 0s in date strings can be confused for an octal number,
    # which is a problem if subsequent digits are greater than 7.
    get show_date_range_path(start_date: "2014-09-01", end_date: "2015-06-30")
    assert_response :success
  end

  def test_index_tails_success
    get tails_path
    assert_response :success
  end
  
  def test_show_tail_success
    get show_tail_path("N12345")
    assert_response :success
  end
  
  def test_index_tails_success
    get classes_path
    assert_response :success
  end
  
  def test_show_class_success
    get show_class_path("Y")
    assert_response :success
  end
  
end