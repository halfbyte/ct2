class AddUserIdToMods < ActiveRecord::Migration
  def change
    add_column :mods, :user_id, :integer

  end
end
