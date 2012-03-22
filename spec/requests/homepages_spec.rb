require 'spec_helper'

describe "Homepages" do
  describe "GET /" do
    it " should work" do
      visit root_path
      page.should have_content("Bootstrapping the world.")
    end
  end
end
