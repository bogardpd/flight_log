# Defines a boarding pass using Apple's PassKit Package (PKPass) format. This
# is used to store Apple Wallet (iOS) boarding passes {BoardingPassEmail
# received} at a specified email address.
#
# PKPass boarding passes are a compressed folder containing a JSON file, which
# itself includes {BoardingPass} barcode data, along with some other metadata
# that can be used to prepopulate {Flight} form fields.
#
# Since all possible flight data is extracted from the PKPass upon creating a
# new {Flight}, the PKPass does not maintain a direct database relationship
# with the {Flight} model. Instead, once a new {Flight} is created, its PKPass
# is destroyed.
# 
# @see BoardingPassEmail
# @see https://developer.apple.com/documentation/passkit/wallet Wallet | Apple Developer Documentation
class PKPass < ApplicationRecord
  after_initialize :set_values
  
  validates :pass_json, :presence => true
  
  # Returns the pass's BCBP barcode data string
  #
  # @return [String] barcode text
  # @see https://www.iata.org/whatwedo/stb/Documents/BCBP-Implementation-Guide-5th-Edition-June-2016.pdf
  #   IATA Bar Coded Boarding Pass (BCBP) Implementation Guide
  def barcode
    if @pass.dig("barcodes")
      return @pass.dig("barcodes", 0, "message")
    else
      return @pass.dig("barcode", "message")
    end
  end
  
  # Returns a {BoardingPass} based on the PKPass's barcode field.
  #
  # @return [BoardingPass] a new {BoardingPass} created from barcode data
  def bcbp
    return BoardingPass.new(barcode)
  end
  
  # Returns a hash of form field values extracted from this PKPass.
  #
  # @return [Hash] a hash with field names as keys, and field values as values
  def form_values
    fields = Hash.new
    
    fields.store(:boarding_pass_data, barcode)
    
    rel_date = @pass.dig("relevantDate")
    if rel_date.present?
      begin
        fields.store(:departure_date, Date.parse(rel_date))
        fields.store(:departure_utc, Time.parse(rel_date).utc)
      rescue ArgumentError
      end
    end
    
    # Look up data from BCBP fields:
    pass = BoardingPass.new(barcode, interpretations: false)
    if pass.is_valid?
      fields.merge!(pass.form_values)
    end
    
    airline_icao = Airline.convert_iata_to_icao(fields[:airline_iata])
    if airline_icao && fields[:flight_number]
      fields.store(:ident, [airline_icao, fields[:flight_number]].join)
    end

    return fields
  end
  
  # Returns an array of hashes of summary details for all PKPasses that are not
  # yet associated with a {Flight}. Used on {FlightsController#new_flight_menu}
  # to show a list of boarding passes that the user can choose to create a
  # {Flight} from.
  #
  # @return [Array<Hash>] all boarding passes not associated with a {Flight}
  def self.pass_summary_list
    PKPass.where(flight_id: nil).map{|pass|
      fields = BoardingPass.new(pass.barcode, interpretations: false).summary_fields
      json_data = JSON.parse(pass.pass_json)
      if json_data["relevantDate"]
        fields.store(:date, Time.parse(json_data["relevantDate"]))
      else
        fields.store(:date, nil)
      end
      fields.store(:id, pass.id)
      fields
    }.sort_by{|h| h[:date] || Time.at(0)}
  end
  
  protected

  # Initializes certain values for the boarding pass.
  #
  # @return [Hash]
  def set_values
    @pass = JSON.parse(self.pass_json)
    self.assign_attributes({:serial_number => [@pass.dig("passTypeIdentifier"),@pass.dig("serialNumber")].join(",")})
  end

end
