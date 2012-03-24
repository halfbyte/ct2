class Mod < ActiveRecord::Base
  mount_uploader :mod_file, ModFileUploader

  attr_accessible :mod_file

  def protracker_module
    mod = nil
    if mod_file
      file = File.open(mod_file.current_path, 'rb')
      mod = ProtrackerModule.read(file)
      puts mod
      file.close
    end
    mod
  end


end
