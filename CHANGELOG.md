# Flight Historian Changelog

## Unreleased

### Added
- Unique slug parameters to `Airline`, `Airport`, and `AircraftFamily` models.
- KML and GPX download links to all maps.
- Switched from FlightXML v2 to [AeroAPI](https://flightaware.com/commercial/aeroapi/) v4 for flight and airport info lookups.

## [2.3] – Automatic Distance Calculations and GPX/KML Maps
2019-04-30

### Added
- Latitudes and longitudes to the `Airport` model.
- [FlightXML API](https://flightaware.com/commercial/flightxml/documentation2.rvt) lookup for latitudes and longitudes when adding new airports.
- Automatic distance calculation for new Routes, using the Haversine formula.
- [Layover ratios](https://paulbogard.net/blog/20190207-my-worst-layovers/) to Show Trip Section views with more than one flight.
- `Map.gpx` and `Map.kml` methods for generating GPX and KML maps.

### Changed
- `Map` class now uses airport IDs instead of IATA codes.
- Renamed `Map.draw` to `Map.gcmap`.

## [2.2] – Regions and Flight Lookups
2018-03-15

### Added
- `FlightXML` module for performing lookups on the [FlightXML API](https://flightaware.com/commercial/flightxml/documentation2.rvt).
- ICAO codes to the `Airport` model.
- Bar Coded Boarding Pass (BCBP) and flight number lookups to New Flight menu.
- Tail number formatting method (`format`) to `TailNumber` module.

### Changed
- Maps can now be filtered by multiple regions (instead of just World and CONUS).
- Regions are now determined by airport ICAO codes.
- Moved existing FlightXML lookups to new `FlightXML` module.
- Tail numbers are now stored with no dashes, and instead formatted using `TailNumber.format`.
- Minor UI and bug fixes.

### Removed
- Functionality for updating existing flights with a new PKPass.
- `is_conus` boolean from `Airport` model, since regions are now determined by ICAO code.

## [2.1] – Import Flights from Digital Boarding Passes
2017-04-29

### Added
- Import Boarding Pass from email functionality (using Apple PKPass boarding passes).
  - `BoardingPass` class for parsing and interpreting Bar Coded Boarding Pass (BCBP) formatted data.
  - `BoardingPassEmail` module for connecting to an IMAP email acccount, finding PKPass attachments, and processing them.
  - `PKPass` model for storing PKPass data.
  - Email and alternate email parameters to `User` model to whitelist valid senders of PKPass attachments.
  - Numeric code parameter to `Airline` model to allow lookups of numeric codes in BCBP data.
  - [JSON API](https://paulbogard.net/boarding-pass-parser/) for parsed boarding pass data.
  - Import Boarding Passes view.
  - Form to allow entry of airport data for BCBP IATA codes not found in the `Airports` table.
  - Form for editing an existing flight with an updated PKPass.
  - Admin view to list any flights with invalid BCBP data.
- New [message banner system](https://paulbogard.net/blog/20170405-creating-multiple-flash-messages-in-ruby-on-rails/), to make all messages look consistent.
- Aircraft types to `AircraftFamily` model, and views to show aircraft types.

### Changed
- Add Flight form now autofills PKPass data when available.

## [2.0] – Flight Historian
2016-01-31

## Added
- [Premium economy](https://www.flighthistorian.com/classes/premium-economy) to list of [travel classes](https://www.flighthistorian.com/classes).
- IATA codes to airlines, aircraft families, and travel classes.
- Aircraft illustrations to aircraft family pages.
- Aircraft name to Show Flight view.
- Tables of operators to Show Aircraft Family, Show Airport, Show Airline, Show Tail Number, Show Route, and Show Travel Class views.
- Region selectors to many more maps.
- Country flags to tail numbers.
- Boarding pass data attribute to `Flight` model.
- Date sanity checking to warn if local departure date and UTC departure datetime are too far apart.

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

### Added
- More details to Show Flights by Year (annual summary) view
- Distances to flights

### Changed
- Minor improvements to New Flight and Edit Flight forms.

## 1.2 – Operators and Codeshares
2014-10-27

### Added
- Operating airlines to flights.
- Fleet numbers to flights.
- Codeshare airlines and codeshare flight numbers to flights.

## 1.1 – Routes and Top 5 Lists
2013-10-24

### Added
- Flight `Route` model, including Index Routes and Show Route views.
- Summary tables to various Show views.
  - Aircraft, airlines, and classes to Show Route views.
  - Origin/destination airports, aircraft, airlines, and classes to Show Airport views.
  - Airlines and classes to Show Aircraft views.
  - Aircraft and classes to Show Airline views.
  - Airlines and aircraft to Show Class views.
  - Classes to Show Tail views.

### Changed
- Rewrote the home page to show flight maps, and top 5 lists and counts of routes, airports, aircraft, airlines, and tails.
- Updated logos and icons for high-DPI displays.
- Switched Tails and Classes on the main navigation bar.
- Minor bug fixes.

## 1.0 – Initial Release
2013-04-27

### Added
- Index Flights and Show Flight views.
- Index Trips, Show Trip, and Show Trip Section views.
- Index Airports and Show Airport views.
- Index Airlines and Show Airline views.
- Index Aircraft Families and Show Aircraft Family views.
- Index Classes and Show Class views.
- Index Tail Numbers and Show Tail Number views.

[2.3]: https://github.com/bogardpd/flight_log/releases/tag/v2.3
[2.2]: https://github.com/bogardpd/flight_log/releases/tag/2.2
[2.1]: https://github.com/bogardpd/flight_log/releases/tag/v2.1
[2.0]: https://github.com/bogardpd/flight_log/releases/tag/v2.0