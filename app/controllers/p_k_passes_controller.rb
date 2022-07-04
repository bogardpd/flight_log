# Manages the {PKPass} {#destroy} action.
#
# No other methods are provided for {PKPass PKPasses} are provided here, since
# {PKPass PKPasses} are only created by parsing raw {BoardingPass} barcode
# data, are only viewed in the context of creating a
# {FlightsController#new_flight_menu new} {Flight} or through the
# {BoardingPass} {FlightsController#show_boarding_pass parser}, and are
# uneditable.
#
# @see BoardingPass
# @see FlightsController#new_flight_menu
# @see FlightsController#show_boarding_pass
class PkPassesController < ApplicationController
  before_action :logged_in_user
  
  # Deletes an existing {PKPass}.
  #
  # @return [nil]
  def destroy
    PKPass.find(params[:id]).destroy
    flash[:success] = "Pass destroyed."
    redirect_to new_flight_menu_path
  end
  
  private
  
end