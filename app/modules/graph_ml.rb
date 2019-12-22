# Provides utilities for generating GraphML XML documents from flight data.
#
# @see http://graphml.graphdrawing.org/ The GraphML File Format
module GraphML

  # Generate a GraphML file for use in the yEd graph editor.
  # 
  # @param flights [Array<Flight>] a collection of {Flight Flights}
  # @param group_edges [Boolean] true to represent multiple routes between
  #   airports as a single edge with proportional line weights; false to keep
  # separate edges 
  # @return [ActiveSupport::Safebuffer] XML for a
  #   {http://graphml.graphdrawing.org GraphML} graph.
  # 
  # @see https://www.yworks.com/products/yed
  def self.yed(flights, group_edges=false)
    flights = flights.includes(:origin_airport, :destination_airport)
    routes = flights.map{|route| [route.origin_airport, route.destination_airport]}
    route_freq = routes.inject(Hash.new(0)){|h,i| h[i] += 1; h }
    max_route_freq = route_freq.values.max
    airports = routes.flatten.uniq
    
    schema = {
      "xmlns":              "http://graphml.graphdrawing.org/xmlns",
      "xmlns:java":         "http://www.yworks.com/xml/yfiles-common/1.0/java",
      "xmlns:sys":          "http://www.yworks.com/xml/yfiles-common/markup/primitives/2.0",
      "xmlns:x":            "http://www.yworks.com/xml/yfiles-common/markup/2.0",
      "xmlns:xsi":          "http://www.w3.org/2001/XMLSchema-instance",
      "xmlns:y":            "http://www.yworks.com/xml/graphml",
      "xmlns:yed":          "http://www.yworks.com/xml/yed/3",
      "xsi:schemaLocation": "http://graphml.graphdrawing.org/xmlns http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd"
    }
    size_ellipse = {width: 32.0, height: 32.0}
        
    output = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
      xml.graphml(schema) do

        xml.key("attr.name": "Description", "attr.type": "string", for: "graph", id: "d0")
        xml.key("attr.name": "description", "attr.type": "string", for: "node", id: "d5")
        xml.key(for: "node", id: "d6", "yfiles.type": "nodegraphics")
        xml.key(for: "graphml", id: "d7", "yfiles.type": "resources")
        xml.key("attr.name": "description", "attr.type": "string", for: "edge", id: "d9")
        xml.key(for: "edge", id: "d10", "yfiles.type": "edgegraphics")

        xml.graph(edgedefault: "directed", id: "G") do
          xml.data(key: "d0")
          
          # Create airports:
          airports.each_with_index do |airport, index|            
            xml.node(id: "n#{airport[:id]}") do
              xml.data(key: "d5")
              xml.data(key: "d6") do
                xml[:y].ShapeNode do
                  xml[:y].Geometry(size_ellipse, position(airports.size, index))
                  xml[:y].NodeLabel(airport[:iata_code], alignment: "center", fontFamily: "Dialog", fontSize: "12", fontStyle: "plain", verticalTextPosition: "bottom", horizontalTextPosition: "center")
                  xml[:y].Shape(type: "ellipse")
                end
              end
            end
          end
          
          # Create flights:
          if group_edges
            route_freq.each_with_index do |(route, freq), edge_id|
              xml.edge(id: "e#{edge_id}", source: "n#{route[0][:id]}", target: "n#{route[1][:id]}") do
                xml.data(key: "d9")
                xml.data(key: "d10") do
                  xml[:y].PolyLineEdge do
                    xml[:y].LineStyle(width: line_width(freq, max_route_freq))
                    xml[:y].Arrows(source: "none", target: "standard")
                  end
                end
              end
            end
          else
            routes.each_with_index do |route, edge_id|              
              xml.edge(id: "e#{edge_id}", source: "n#{route[0][:id]}", target: "n#{route[1][:id]}")
            end
          end

        end
        xml.data(key: "d7") do
          xml[:y].Resources
        end
      end
    end

    output = output.to_xml
    
    return output
  end

  private

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

  # Calculates a line width based on the frequency of a certain route compared
  # to the maximum frequency.
  # @param freq [Integer] the frequency of the route
  # @param max_freq [Integer] the highest frequency of all routes
  # @return [Integer] a line width
  def self.line_width(freq, max_freq)
    line_width_range = 1..5
    return (freq.to_f / max_freq) * (line_width_range.end - line_width_range.begin) + line_width_range.begin
  end

end