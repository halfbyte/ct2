require 'tempfile'
class Mod < ActiveRecord::Base
  mount_uploader :mod_file, ModFileUploader

  attr_accessible :mod_file

  def protracker_module
    mod = nil
    if mod_file
      file = File.open(mod_file.current_path, 'rb')
      mod = ProtrackerModule.read(file)
      file.close
    end
    mod
  end

  def update_module(data)
    mod = protracker_module
    mod.update_from_json(data)
    file = Tempfile.new('tmp.mod', nil, :encoding => 'ascii-8bit')
    mod.write(file)
    file.rewind
    self.mod_file = file
    file.close
    save
  end


end
