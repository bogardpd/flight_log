# encoding: UTF-8

require 'spec_helper'

describe PagesController do
  render_views

  describe "GET 'home'" do
    it "returns http success" do
      get 'home'
      response.should be_success
    end
    
    it "should have the right title" do
      get 'home'
      response.should have_selector("title", :content => "Paul Bogard")
    end
  end

  describe "GET 'about'" do
    it "returns http success" do
      get 'about'
      response.should be_success
    end
    
    it "should have the right title" do
      get 'about'
      response.should have_selector("title", :content => "About Paul - Paul Bogard")
    end
  end

  describe "GET 'projects'" do
    it "returns http success" do
      get 'projects'
      response.should be_success
    end
    
    it "should have the right title" do
      get 'projects'
      response.should have_selector("title", :content => "Projects - Paul Bogard")
    end
  end

  describe "GET 'resume'" do
    it "returns http success" do
      get 'resume'
      response.should be_success
    end
    
    it "should have the right title" do
      get 'resume'
      response.should have_selector("title", :content => "Résumé - Paul Bogard")
    end
  end
  
  describe "GET 'modeling'" do
    it "returns http success" do
      get 'modeling'
      response.should be_success
    end
    
    it "should have the right title" do
      get 'modeling'
      response.should have_selector("title", :content => "CAD 3D Models - Paul Bogard")
    end
  end
  
  describe "GET 'flight_log'" do
    it "returns http success" do
      get 'flight_log'
      response.should be_success
    end

    it "should have the right title" do
      get 'flight_log'
      response.should have_selector("title", :content => "Creating Paul Bogard's Flight Log - Paul Bogard")
    end
  end
  
  describe "GET 'gps_log'" do
    it "returns http success" do
      get 'gps_log'
      response.should be_success
    end

    it "should have the right title" do
      get 'gps_log'
      response.should have_selector("title", :content => "GPS Log - Paul Bogard")
    end
  end
  
  describe "GET 'gps_logging_garmin'" do
    it "returns http success" do
      get 'gps_logging_garmin'
      response.should be_success
    end

    it "should have the right title" do
      get 'gps_logging_garmin'
      response.should have_selector("title", :content => "Garmin GPS Logging - Paul Bogard")
    end
  end

  describe "GET 'gps_logging_iphone'" do
    it "returns http success" do
      get 'gps_logging_iphone'
      response.should be_success
    end

    it "should have the right title" do
      get 'gps_logging_iphone'
      response.should have_selector("title", :content => "iPhone GPS Logging - Paul Bogard")
    end
  end

  describe "GET 'turn_signal_counter'" do
    it "returns http success" do
      get 'turn_signal_counter'
      response.should be_success
    end

    it "should have the right title" do
      get 'turn_signal_counter'
      response.should have_selector("title", :content => "Turn Signal Counter - Paul Bogard")
    end
  end

  describe "GET 'hotel_internet_quality'" do
    it "returns http success" do
      get 'hotel_internet_quality'
      response.should be_success
    end

    it "should have the right title" do
      get 'hotel_internet_quality'
      response.should have_selector("title", :content => "Hotel Internet Quality - Paul Bogard")
    end
  end
  
  describe "GET 'visor_cam'" do
    it "returns http success" do
      get 'visor_cam'
      response.should be_success
    end

    it "should have the right title" do
      get 'visor_cam'
      response.should have_selector("title", :content => "Visor Cam - Paul Bogard")
    end
  end
  
  describe "GET 'ebdb'" do
    it "returns http success" do
      get 'ebdb'
      response.should be_success
    end

    it "should have the right title" do
      get 'ebdb'
      response.should have_selector("title", :content => "EarthBound Database - Paul Bogard")
    end
  end
  
  describe "GET 'current_home'" do
    it "returns http success" do
      get 'current_home'
      response.should be_success
    end

    it "should have the right title" do
      get 'current_home'
      response.should have_selector("title", :content => "Paul's Current Home - Paul Bogard")
    end
  end
  
  describe "Flight Log application" do
    
    describe "GET 'flightlog'" do
      it "returns http success" do
        get 'flightlog'
        response.should be_success
      end

      it "should have the right title" do
        get 'flightlog'
        response.should have_selector("title", :content => "Paul Bogard's Flight Log")
      end
    end
  
  end

end
