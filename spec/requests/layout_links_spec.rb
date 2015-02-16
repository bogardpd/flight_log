# encoding: UTF-8

require 'spec_helper'

describe "LayoutLinks" do
  
  it "should have a Home page at '/'" do
    get '/'
    response.should have_selector('title', :content => "Paul Bogard")
  end
  
  it "should have a Projects page at '/projects'" do
    get '/projects'
    response.should have_selector('title', :content => "Projects - Paul Bogard")
  end
  
  it "should have a Résumé page at '/resume'" do
    get '/resume'
    response.should have_selector('title', :content => "Résumé - Paul Bogard")
  end
  
  it "should have an About page at '/about'" do
    get '/about'
    response.should have_selector('title', :content => "About Paul - Paul Bogard")
  end
  
  it "should have a 3D Modeling page at '/modeling'" do
    get '/modeling'
    response.should have_selector('title', :content => "CAD 3D Models - Paul Bogard")
  end
  
  it "should have a GPS Log page at '/gps_log'" do
    get '/gps_log'
    response.should have_selector('title', :content => "GPS Log - Paul Bogard")
  end
  
  it "should have a Flight Log page at '/flight_log'" do
    get '/flight_log'
    response.should have_selector('title', :content => "Creating Paul Bogard's Flight Log - Paul Bogard")
  end
  
  it "should have a Garmin GPS Logging page at '/gps_logging_garmin'" do
    get '/gps_logging_garmin'
    response.should have_selector('title', :content => "Garmin GPS Logging - Paul Bogard")
  end
  
  it "should have a iPhone GPS Logging page at '/gps_logging_iphone'" do
    get '/gps_logging_iphone'
    response.should have_selector('title', :content => "iPhone GPS Logging - Paul Bogard")
  end

  it "should have a Hotel Internet Quality page at '/hotel_internet_quality'" do
    get '/hotel_internet_quality'
    response.should have_selector('title', :content => "Hotel Internet Quality - Paul Bogard")
  end
  
  it "should have a Visor Cam page at '/visor_cam'" do
    get '/visor_cam'
    response.should have_selector('title', :content => "Visor Cam - Paul Bogard")
  end
  
  it "should have a Hotel Internet Quality page at '/ebdb'" do
    get '/ebdb'
    response.should have_selector('title', :content => "EarthBound Database - Paul Bogard")
  end
  
  
  it "should have the right links in the nav bar" do
    visit root_path
    click_link "projects"
    response.should have_selector('title', :content => "Projects - Paul Bogard")
    click_link "résumé"
    response.should have_selector('title', :content => "Résumé - Paul Bogard")
    click_link "about"
    response.should have_selector('title', :content => "About Paul - Paul Bogard")
    click_link "home"
    response.should have_selector('title', :content => "Paul Bogard")
  end
  
  it "should have the right links on the Project page" do
    visit projects_path
    click_link "CAD 3D Models"
    response.should have_selector('title', :content => "CAD 3D Models - Paul Bogard")
    
    visit projects_path
    click_link "GPS Log"
    response.should have_selector('title', :content => "GPS Log - Paul Bogard")
    visit gps_log_path
    click_link "Garmin GPS Logging"
    response.should have_selector('title', :content => "Garmin GPS Logging - Paul Bogard")
    
    visit projects_path
    click_link "Flight Log"
    response.should have_selector('title', :content => "Creating Paul Bogard's Flight Log - Paul Bogard")
    
    visit projects_path
    click_link "Turn Signal Counter"
    response.should have_selector('title', :content => "Turn Signal Counter - Paul Bogard")
    
    visit projects_path
    click_link "Hotel Internet Quality"
    response.should have_selector('title', :content => "Hotel Internet Quality - Paul Bogard")
        
    visit projects_path
    click_link "Visor Cam"
    response.should have_selector('title', :content => "Visor Cam - Paul Bogard")
        
    visit projects_path
    click_link "EarthBound Database"
    response.should have_selector('title', :content => "EarthBound Database - Paul Bogard")
  end
  
end
