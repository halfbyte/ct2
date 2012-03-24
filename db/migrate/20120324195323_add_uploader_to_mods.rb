class AddUploaderToMods < ActiveRecord::Migration
  def up
    add_column :mods, :mod_file, :string
  end

  def down
    remove_column :mods, :mod_file
  end
end
