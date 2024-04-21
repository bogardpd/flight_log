# Provides utilities for generating GraphML XML documents from flight data.
#
# @see http://graphml.graphdrawing.org/ The GraphML File Format
module GraphML

  # Styles to use for graphs.
  BASE_STYLES = {
    edge_width: 2.0, # px
    node_diameter: 30.0, # px
    node_font_divisor: 2.4, # Ratio of circle diameter to font size
    node_color_fill: "#DBDCDF",
    node_color_border: "#303236",
    node_color_font: "#303236",
    node_width_border: 1.0, # px
  }

  # Default colors for airlines (based on the airline's name).
  AIRLINE_COLORS = {
    "AirTran"           => "#2db7b7",
    "American Airlines" => "#ff99cc",
    "Delta"             => "#cc0000",
    "Southwest"         => "#ff9900",
    "United"            => "#3366ff",
    "US Airways"        => "#cccccc",
  }

  # Location to save temporary GraphML files.
  TEMP_FILE = "tmp/flights.graphml"

    # XML schema for yEd documents.
  YED_SCHEMA = {
    "xmlns":              "http://graphml.graphdrawing.org/xmlns",
    "xmlns:java":         "http://www.yworks.com/xml/yfiles-common/1.0/java",
    "xmlns:sys":          "http://www.yworks.com/xml/yfiles-common/markup/primitives/2.0",
    "xmlns:x":            "http://www.yworks.com/xml/yfiles-common/markup/2.0",
    "xmlns:xsi":          "http://www.w3.org/2001/XMLSchema-instance",
    "xmlns:y":            "http://www.yworks.com/xml/graphml",
    "xmlns:yed":          "http://www.yworks.com/xml/yed/3",
    "xsi:schemaLocation": "http://graphml.graphdrawing.org/xmlns http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd"
  }

  # Generate a GraphML file for use in the yEd graph editor from a collection of
  # {Flight flights}.
  #
  # This method also saves the output to the file location specified in
  # TEMP_FILE. It will be overwritten each time the method is run.
  # 
  # @param flights [Array<Flight>] a collection of {Flight Flights}
  # @return [Object] XML for a {http://graphml.graphdrawing.org GraphML} graph.
  # 
  # @see https://www.yworks.com/products/yed
  def self.graph_flights(flights)
    flights = flights.includes(:origin_airport, :destination_airport, :airline)
    
    airport_nodes = Airport.visit_table_data(flights).map{|a| {id: a[:id], text: a[:iata_code], visits: a[:visit_count]}}
    flight_edges = flights.map{|f| {source: f.origin_airport_id, target: f.destination_airport_id, airline: f.airline.name}}

    output = build_yed_xml(airport_nodes, flight_edges)

    write_temp_file(output)

    return output
  end

  # Generate a GraphML file for use in the yEd graph editor from a string of
  # airports.
  #
  # This method also saves the output to the file location specified in
  # TEMP_FILE. It will be overwritten each time the method is run.
  # 
  # @param flight_string [String] a string of airport codes in the format
  #   "JFK-ORD-LAX,LAX-DFW-JFK" where hyphens are flights, and commas are the
  #    end of a one way trip (generally when the traveler leaves the airport).
  # @return [Object] XML for a {http://graphml.graphdrawing.org GraphML} graph.
  # 
  # @see https://www.yworks.com/products/yed
  def self.parse(flight_string)
    flight_string.upcase!
    airports = flight_string.split(/[,-]/)
      .tally
      .map{|a, v| {id: a, text: a, visits: v}}
    flights = flight_string.split(",")
      .map{|section| section.split("-").each_cons(2).to_a}
      .flatten(1)
      .map{|f| {source: f[0], target: f[1]}}

    output = build_yed_xml(airports, flights)

    write_temp_file(output)

    return output
  end

  private

  # Creates yEd GraphML XML from arrays of nodes and edges.
  #
  # @param nodes [Array<Hash>] An array of node hashes in the format
  #   [{id:, text:, visits:}]
  # @param edges [Array<Hash>] An array of edge hashes in the format
  #   [{source:, target:, airline:}]. Source and target refer to node ids, and
  #   airline is optional.
  # @return [Object] XML for a {http://graphml.graphdrawing.org GraphML} graph.
  def self.build_yed_xml(nodes, edges)
    output = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
      xml.graphml(YED_SCHEMA) do

        xml.key("attr.name": "Description", "attr.type": "string", for: "graph", id: "d0")
        xml.key("attr.name": "description", "attr.type": "string", for: "node", id: "d5")
        xml.key(for: "node", id: "d6", "yfiles.type": "nodegraphics")
        xml.key(for: "graphml", id: "d7", "yfiles.type": "resources")
        xml.key("attr.name": "description", "attr.type": "string", for: "edge", id: "d9")
        xml.key(for: "edge", id: "d10", "yfiles.type": "edgegraphics")

        xml.graph(edgedefault: "directed", id: "G") do
          xml.data(key: "d0")
          
          # Create airports:
          nodes.each_with_index do |node, index|
            xml.node(id: "n#{node[:id]}") do
              xml.data(key: "d5")
              xml.data(key: "d6") do
                xml[:y].ShapeNode do
                  xml[:y].Geometry(circle_size(node[:visits]), position(nodes.size, index))
                  xml[:y].Fill(color: BASE_STYLES[:node_color_fill], transparent: false)
                  xml[:y].BorderStyle(color: BASE_STYLES[:node_color_border], raised: false, type: "line", width: BASE_STYLES[:node_width_border])
                  xml[:y].NodeLabel(node[:text], **font(node[:visits]))
                  xml[:y].Shape(type: "ellipse")
                end
              end
            end
          end
          
          # Create flights:
          edges.sort_by{|e| e[:airline]}.each_with_index do |flight, edge_id|              
            xml.edge(id: "e#{edge_id}", source: "n#{flight[:source]}", target: "n#{flight[:target]}") do
              xml.data(key: "d9")
              xml.data(key: "d10") do
                xml[:y].PolyLineEdge do
                  color = AIRLINE_COLORS[flight[:airline]] || BASE_STYLES[:node_color_border]
                  xml[:y].LineStyle(width: BASE_STYLES[:edge_width], color: color)
                  xml[:y].Arrows(source: "none", target: "standard")
                  xml[:y].EdgeLabel(flight[:airline], visible: false) if flight[:airline]
                end
              end
            end
          end
          
        end
        xml.data(key: "d7") do
          xml[:y].Resources
        end
      end
    end

    return output.to_xml
  end

  # Writes XML to a temporary file.
  # 
  # @param xml [Object] XML to write to file
  # @return [nil]
  def self.write_temp_file(xml)
    f = File.open(TEMP_FILE, "w")
    f << xml
    f.close
    return nil
  end

  # Calculates the X,Y position of a node in an evenly-spaced circle of elements
  # based on the number of nodes in the circle and the index of the node.
  #
  # @param node_count [Integer] the number of nodes in the circle
  # @param node_index [Integer] the position of the node, from 0 to node_count
  #   minus one
  # @return [Hash] an x,y hash
  def self.position(node_count, node_index)
    radius_multiplier = 10
    radius = node_count * radius_multiplier
    angle_per_node = (2 * Math::PI) / node_count
    x = radius * Math.cos(angle_per_node * node_index)
    y = radius * Math.sin(angle_per_node * node_index)
    return {x: x, y: y}
  end

  # Calculates the width and height of a node based on the number of visits to
  # an airport.
  # 
  # @param visits [Integer] the number of visits to an airport
  # @return [Hash] a width,height hash
  def self.circle_size(visits)
    return {width: diameter(visits), height: diameter(visits)}
  end

  # Calculates the diameter of a node based on the number of visits to
  # an airport.
  # 
  # @param visits [Integer] the number of visits to an airport
  # @return [Float] the diameter in pixels
  def self.diameter(visits)
    return BASE_STYLES[:node_diameter] * Math.sqrt(visits)
  end

  # Creates node text attributes based on the number of visits to an airport.
  # 
  # @param visits [Integer] the number of visits to an airport
  # @return [Hash] a hash of font options
  def self.font(visits)
    font_size = (diameter(visits) / BASE_STYLES[:node_font_divisor]).to_i.to_s
    return {alignment: "center", fontFamily: "Source Sans 3 Semibold", fontSize: font_size, fontStyle: "plain", verticalTextPosition: "bottom", horizontalTextPosition: "center"}
  end

end