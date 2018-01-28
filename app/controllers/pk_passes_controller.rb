class PkPassesController < ApplicationController
  before_action :logged_in_user
  
  def destroy
    PKPass.find(params[:id]).destroy
    flash[:success] = "Pass destroyed."
    redirect_to new_flight_menu_path
  end
  
  private
  
    
  
end