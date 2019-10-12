# Provides controller methods for the entire application.
class ApplicationController < ActionController::Base
  protect_from_forgery
  
  include SessionsHelper
  
  # Returns an array of region ICAO code prefixes (e.g. ["K","PH"]) based on
  # the region parameter in the URL if present, and the default if absent.
  #
  # @param default [Array<String>] a set of region ICAO code prefixes to use
  #   if params does not contain a region.
  # @return [Array<String>] the parameter region if present, otherwise the
  #   provided default region
  def current_region(default: [])
    return default unless params[:region]
    icao_starts = params[:region].split(/[\-,]/)
    icao_starts.compact!
    icao_starts.uniq!
    icao_starts.map!{|s| s.upcase.tr("^A-Z","")}
    return icao_starts
  end
  
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
      redirect_to root_url
    end
  end
  
  # Gets attachments from boarding pass emails.
  #
  # @return [nil]
  def check_email_for_boarding_passes
    begin
      BoardingPassEmail::process_attachments(current_user.all_emails)
    rescue => details
      flash.now[:warning] = "Could not get new passes from email (#{details})"
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
