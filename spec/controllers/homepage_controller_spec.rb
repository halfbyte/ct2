require 'spec_helper'

describe HomepageController do
  describe "GET index" do
    it "should work" do
      get :index
      response.status.should be(200)
    end
  end
end
