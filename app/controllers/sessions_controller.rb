# Controls pages and actions dealing with managing user sessions.
class SessionsController < ApplicationController
  
  # Shows a login form.
  #
  # @return [nil]
  def new
    @title = "Log In"
  end
  
  # Creates a new user session (logs a user in).
  #
  # @return [nil]
  # @see SessionsHelper#log_in
  def create
    user = User.find_by_name(params[:session][:name])
    if user && user.authenticate(params[:session][:password])
      log_in user
      redirect_to root_path
    else
      flash.now[:error] = "Invalid username/password combination"
      render "new"
    end
  end
  
  # Destroys an existing user session (logs a user out).
  #
  # @return [nil]
  # @see SessionsHelper#log_out
  def destroy
    log_out
    redirect_to root_path
  end
  
end
