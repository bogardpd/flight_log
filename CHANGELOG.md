# Flight Historian Changelog

## [2.4] - GPX/KML Map Downloads and AeroAPI
2022-07-04

### New
- Added KML and GPX download links to all maps.
- Added unique slug parameters to `Airline`, `Airport`, and `AircraftFamily` models.

### Changed
- Switched from FlightXML v2 to [AeroAPI](https://flightaware.com/commercial/aeroapi/) v4 for flight and airport info lookups.
- Upgraded from Rails 6.1 to Rails 7.0.

## [2.3] – Automatic Distance Calculations and GPX/KML Maps
2019-04-30

### New
- Added latitudes and longitudes to the `Airport` model.
- Added [FlightXML API](https://flightaware.com/commercial/flightxml/documentation2.rvt) lookup for latitudes and longitudes when adding new airports.
- Added automatic distance calculation for new Routes, using the Haversine formula.
- Added [layover ratios](https://paulbogard.net/posts/my-worst-layovers/) to Show Trip Section views with more than one flight.
- Created `Map.gpx` and `Map.kml` methods for generating GPX and KML maps.

### Changed
- `Map` class now uses airport IDs instead of IATA codes.
- Renamed `Map.draw` to `Map.gcmap`.

## [2.2] – Regions and Flight Lookups
2018-03-15

### New
- Created `FlightXML` module for performing lookups on the [FlightXML API](https://flightaware.com/commercial/flightxml/documentation2.rvt).
- Added ICAO codes to the `Airport` model.
- Added Bar Coded Boarding Pass (BCBP) and flight number lookups to New Flight menu.
- Created tail number formatting method (`format`) to `TailNumber` module.

### Changed
- Maps can now be filtered by multiple regions (instead of just World and CONUS).
- Regions are now determined by airport ICAO codes.
- Moved existing FlightXML lookups to new `FlightXML` module.
- Tail numbers are now stored with no dashes, and instead formatted using `TailNumber.format`.
- Minor UI and bug fixes.

### Removed
- Removed functionality for updating existing flights with a new PKPass.
- Removed `is_conus` boolean from `Airport` model, since regions are now determined by ICAO code.

## [2.1] – Import Flights from Digital Boarding Passes
2017-04-29

### New
- Created Import Boarding Pass from Email functionality (using Apple PKPass boarding passes).
  - Created `BoardingPass` class for parsing and interpreting Bar Coded Boarding Pass (BCBP) formatted data.
  - Created `BoardingPassEmail` module for connecting to an IMAP email acccount, finding PKPass attachments, and processing them.
  - Created `PKPass` model for storing PKPass data.
  - Added email and alternate email parameters to `User` model (enables whitelisting of valid senders of PKPass attachments.
  - Added numeric code parameter to `Airline` model (enables lookups of numeric codes in BCBP data).
  - Added [JSON API](https://paulbogard.net/boarding-pass-parser/) for parsed boarding pass data.
  - Added Import Boarding Passes view.
  - Added a form to allow entry of airport data for BCBP IATA codes not found in the `Airports` table.
  - Added a form for editing an existing flight with an updated PKPass.
  - Added an admin view to list any flights with invalid BCBP data.
- Created a new [message banner system](https://paulbogard.net/blog/20170405-creating-multiple-flash-messages-in-ruby-on-rails/), to make all messages look consistent.
- Added aircraft types to `AircraftFamily` model, and views to show aircraft types.

### Changed
- Add Flight form now autofills PKPass data when available.

## [2.0] – Flight Historian
2016-01-31

## New
- Added [premium economy](https://www.flighthistorian.com/classes/premium-economy) to list of [travel classes](https://www.flighthistorian.com/classes).
- Added IATA codes to airlines, aircraft families, and travel classes.
- Added aircraft illustrations to aircraft family pages.
- Added aircraft name to Show Flight view.
- Added tables of operators to Show Aircraft Family, Show Airport, Show Airline, Show Tail Number, Show Route, and Show Travel Class views.
- Added region selectors to many more maps.
- Added country flags to tail numbers.
- Added boarding pass data attribute to `Flight` model.
- Added date sanity checking to warn if local departure date and UTC departure datetime are too far apart.

## Changed
- Separated Flight Log from being part of [Portfolio](https://www.pbogard.com) into [its own site](https://www.flighthistorian.com).
  - Renamed Flight Log to Flight Historian.
  - Replaced favicon.
- Upgraded Ruby from 1.8 to 2.2.
- Upgraded Rails from 3.2 to 4.2.
- Converted database from MySQL to PostgreSQL.
- Converted stylesheets to [SCSS](http://sass-lang.com/).
- Optimized database queries and page rendering to make pages load faster.
- Airlines are now their own `Airline` model rather than an attribute of `Flight`.
- Aircraft families are now their own `AircraftFamily` model rather than an attribute of `Flight`.
- Moved list of flights to the end of Show views, and provided a link to the list of flights section under the flight map for each of these views.
- Rewrote [Great Circle Mapper](http://gcmap.com/) map generating functions to be more consistent.
- All maps now use the same color scheme.
- Minor typo fixes.

## 1.3 – Distances and Annual Summaries
2015-02-08

### New
- Added more details to Show Flights by Year (annual summary) view
- Added distances to flights

### Changed
- Minor improvements to New Flight and Edit Flight forms.

## 1.2 – Operators and Codeshares
2014-10-27

### New
- Added operating airlines to flights.
- Added fleet numbers to flights.
- Added codeshare airlines and codeshare flight numbers to flights.

## 1.1 – Routes and Top 5 Lists
2013-10-24

### New
- Added flight `Route` model, including Index Routes and Show Route views.
- Added summary tables to various Show views.
  - Added aircraft, airlines, and classes to Show Route views.
  - Added origin/destination airports, aircraft, airlines, and classes to Show Airport views.
  - Added airlines and classes to Show Aircraft views.
  - Added aircraft and classes to Show Airline views.
  - Added airlines and aircraft to Show Class views.
  - Added classes to Show Tail views.

### Changed
- Rewrote the home page to show flight maps, and top 5 lists and counts of routes, airports, aircraft, airlines, and tails.
- Changed the [airport frequency map](https://www.flighthistorian.com/airports#airport-frequency-map) to represent the number of visits with circle area instead of circle radius.
- Updated logos and icons for high-DPI displays.
- Switched Tails and Classes on the main navigation bar.
- Minor bug fixes.

## 1.0 – Initial Release
2013-04-27

### New
- Created Index Flights and Show Flight views.
- Created Index Trips, Show Trip, and Show Trip Section views.
- Created Index Airports and Show Airport views.
- Created Index Airlines and Show Airline views.
- Created Index Aircraft Families and Show Aircraft Family views.
- Created Index Classes and Show Class views.
- Created Index Tail Numbers and Show Tail Number views.

[2.4]: https://github.com/bogardpd/flight_log/releases/tag/v2.4
[2.3]: https://github.com/bogardpd/flight_log/releases/tag/v2.3
[2.2]: https://github.com/bogardpd/flight_log/releases/tag/2.2
[2.1]: https://github.com/bogardpd/flight_log/releases/tag/v2.1
[2.0]: https://github.com/bogardpd/flight_log/releases/tag/v2.0