class UsersController < ApplicationController
  def show
    redirect_to root_path if !logged_in?
    @user = User.find(params[:id])
    @title = @user.name
  end
  
  def new
    redirect_to root_path if !logged_in?
    @user = User.new
    @title = "Sign Up"
  end
  
  def create
    redirect_to root_path if !logged_in?
    @user = User.new(params[:user])
    if @user.save
      flash[:success] = ("User <strong>" + @user.name + "</strong> was successfully created!").html_safe
      redirect_to root_path
    else
      render 'new'
    end
  end
  
  def index
    redirect_to root_path if !logged_in?
    @users = User.all
  end

end
