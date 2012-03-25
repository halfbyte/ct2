class HomepageController < ApplicationController

  def index
    @public_mods = Mod.limit(20).all

  end

end