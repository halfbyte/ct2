class ApplicationController < ActionController::Base  
  protect_from_forgery

  helper_method :current_user, :signed_in?

  private

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  
  def signed_in?
    !!current_user
  end
  
  def login_required!
    signed_in? || redirect_to(login_url, :notice => "Action needs login")
  end

end
