# Provides controller methods for the entire application.
class ApplicationController < ActionController::Base
  protect_from_forgery

  include SessionsHelper

  # Returns the {User} whose flights are being viewed. Until multiple user
  # functionality is added to Flight Historian, this will simply return the
  # first user.
  #
  # @return [User] the {User} whose flights are being viewed
  def flyer
    return User.first
  end
  helper_method :flyer

  # Redirects to the root page unless the user is logged in.
  #
  # @return [nil]
  def logged_in_user
    unless logged_in?
      redirect_to login_url
    end
  end

  # Renders content if data is present.
  #
  # @param data [Object] the content to render
  # @param rails_type [Symbol] the rails type of content to render (e.g. `:json` or `:xml`)
  # @param content_type [String] the IANA media type of the content, if more specific than the rails_type
  def render_extension(data, rails_type, content_type=nil)
    render(rails_type => data, content_type: content_type) if data
  end

  # Renders different map formats if an appropriate extension is present.
  #
  # @param maps [Hash] a hash of maps on the view
  # @param map_id [String] the map to generate a different format for
  # @param extension [String] the type of format to render
  def render_map_extension(maps, map_id, extension)
    return unless maps && maps.any? && map_id && extension
    map_sym = map_id.to_sym
    return unless maps.keys.include?(map_sym)

    case extension
    when "gpx"
      render_extension(maps[map_sym].gpx, :xml, 'application/gpx+xml')
    when "kml"
      render_extension(maps[map_sym].kml, :xml, 'application/vnd.google-earth.kml+xml')
    when "geojson"
      render_extension(maps[map_sym].geojson, :json, 'application/geo+json')
    when "graphml"
      render_extension(maps[map_sym].graphml, :xml)
    end
  end

  # Gets attachments from boarding pass emails.
  #
  # @return [nil]
  def check_email_for_boarding_passes
    begin
      BoardingPassS3::fetch_passes()
    rescue => details
      add_message(:warning, "Could not get new passes from email (#{details})")
    end
  end

  # Adds a message to the alert messages box at the top of the page.
  #
  # @param type [:info, :success, :warning, :error] the type of message to
  #   display. Used to determine the color of the message box.
  # @param text [String] the message text
  # @param id [String] an optional ID for the message block
  # @return [nil]
  def add_message(type, text, id=nil)
    @messages ||= []
    @messages.push({type: type, text: text, id: id})
  end

end
