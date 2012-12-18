require 'spec_helper'

describe UsersController do

  describe "GET 'index'" do
    it "returns http success" do
      get 'index'
      response.should be_success
    end
  end

  # describe "GET 'show'" do
  #   it "returns http success" do
  #     puts User.all.inspect
  #     get 'show', :id => 'halfbyte'
  #     response.should be_success
  #   end
  # end

end
