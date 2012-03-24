class CreateMods < ActiveRecord::Migration
  def change
    create_table :mods do |t|
      t.string :title
      t.boolean :is_public

      t.timestamps
    end
  end
end
