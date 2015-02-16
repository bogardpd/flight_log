class SessionsController < ApplicationController
  
  def new
    @title = "Log In"
  end
  
  def create
    user = User.find_by_name(params[:session][:name])
    if user && user.authenticate(params[:session][:password])
      log_in user
      redirect_to root_path
    else
      flash.now[:error] = 'Invalid username/password combination'
      render 'new'
    end
  end
  
  def destroy
    log_out
    redirect_to root_path
  end
  
end
