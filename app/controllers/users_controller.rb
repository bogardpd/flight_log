# Controls {User} pages and actions.
#
# Since multi-user functionality is not yet implemented in this application,
# these pages and actions are only used to support a single user and have very
# little implemented functionality at this time. If multi-user functionality is
# added, this controller will require substantial modification.
# 
# All of these actions currently require a verified user.
class UsersController < ApplicationController

  before_action :logged_in_user
  
  # Shows details about a particular {User}.
  #
  # Since multi-user functionality is not yet implemented in this application,
  # this view is simply a stub and only shows the username.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def show
    @user = User.find(params[:id])
    @title = @user.name
  end
  
  # Shows a form to add (sign up) a {User}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def new
    @user = User.new
    @title = "Sign Up"
  end
  
  # Creates a new {User}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def create
    @user = User.new(user_params)
    if @user.save
      flash[:success] = ("User " + ActionController::Base.helpers.content_tag(:strong, @user.name) + " was successfully created!")
      redirect_to root_path
    else
      render "new"
    end
  end
  
  # Shows a list of all {User Users}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def index
    @users = User.all
  end

  private
  
  # Defines permitted {User} parameters.
  #
  # @return [ActionController::Parameters]
  def user_params
    params.require(:user).permit(:name, :password, :password_confirmation, :email, :alternate_email)
  end
    
end
