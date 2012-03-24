class ModsController < ApplicationController


  # lets you upload a new mod
  def new

  end

  # uploads module, sets title
  # or, without upload, creates empty module shell
  def create

  # html - renders editor
  # json - renders jsonmod
  # js - renders playerbadge?
  # without user, the mod needs to be public
  def show  

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
