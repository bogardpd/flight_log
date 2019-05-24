# Defines helper methods dealing with managing the login status of {User Users}.
module SessionsHelper
  
  # Creates a new session by logging a {User} in.
  #
  # @param user [User] the user to log in
  # @return [User] the user that was logged in
  def log_in(user)
    cookies.permanent[:remember_token] = user.remember_token
    self.current_user = user
  end
  
  # Determines whether the current site visitor is a logged-in {User}.
  #
  # @return [Boolean] whether or not the current site visitor is a logged-in user
  def logged_in?
    !current_user.nil?
  end
  
  # Sets the current logged-in {User}.
  #
  # @param user [User] the user to set the current user to
  # @return [User] the user that was set
  def current_user=(user)
    @current_user = user
  end
  
  # Returns the current logged-in {User}, or nil if the current visitor is not
  # a logged-in {User}.
  #
  # @return [User, nil] the current logged-in user
  def current_user
    return nil if cookies[:remember_token].nil?
    @current_user ||= User.find_by_remember_token(cookies[:remember_token])
  end
  
  # Ends a session by logging the current {User} out.
  #
  # @return [nil]
  def log_out
    self.current_user = nil
    cookies.delete(:remember_token)
  end
end
