class UsersController < ApplicationController
  def index
  end

  def show
    @user = User.find_by_nickname(params[:id])
    if @user.nil?
      raise ActiveRecord::RecordNotFound
    end
  end
end
