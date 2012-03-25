class ModsController < ApplicationController


  # lets you upload a new mod
  def new
    @mod = Mod.new
  end

  # uploads module, sets title
  # or, without upload, creates empty module shell
  def create
    @mod = Mod.new(params[:mod])
    if @mod.save
      redirect_to @mod, :notice => 'module successfully uploaded'
    else
      render 'new'
    end
  end
  # html - renders editor
  # json - renders jsonmod
  # js - renders playerbadge?
  # without user, the mod needs to be public
  def show  
    @mod = Mod.find(params[:id])
    @pt = @mod.protracker_module
    puts "AHA #{@pt.sample_data[0].snapshot.length}"
  end

  # html - renders player only
  def play

  end

  # renders public mods if called without user
  # renders all your mods
  def index

  end

  # patches a given module or replaces it (needs deep merge algo)
  def update

  end

end
