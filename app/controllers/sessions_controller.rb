class SessionsController < ApplicationController

  def new

  end

  def create
    auth = request.env["omniauth.auth"]
    puts auth.inspect
    user = User.by_oauth(auth)
    session[:user_id] = user.id
    redirect_to request.env["omniauth.url"] || root_url, :notice => "Signed in!"
  end

  def destroy
    session.delete(:user_id)
    redirect_to root_url, :notice => "Signed out!"
  end

end
