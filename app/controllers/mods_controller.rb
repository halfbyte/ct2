class ModsController < ApplicationController
  before_filter :login_required!, :only => [:create, :update]
  before_filter :load_user, :only => [:show, :index, :play]
  before_filter :load_mod, :only => [:show, :play]

  # lets you upload a new mod
  def new
    @mod = Mod.new
  end

  # uploads module, sets title
  # or, without upload, creates empty module shell
  def create
    @mod = current_user.mods.build(params[:mod])
    if @mod.save
      redirect_to user_mod_path(current_user, @mod), :notice => 'module successfully uploaded'
    else
      render 'new'
    end
  end
  # html - renders editor
  # json - renders jsonmod
  # js - renders playerbadge?
  # without user, the mod needs to be public
  def show  
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
    @mod = current_user.mods.find(params[:id])
    @mod.update_module(JSON.parse(params[:data]))

    render :json => {ok: 'cheers mate'}
  end
private
  def load_user
    @user = User.find_by_nickname(params[:user_id])
  end

  def load_mod
    @mod = @user.mods.find(params[:id])
  end

end
