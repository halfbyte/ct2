class CreateSamples < ActiveRecord::Migration
  def change
    create_table :samples do |t|
      t.integer :user_id
      t.boolean :is_public
      t.string :name
      t.string :file

      t.timestamps
    end
  end
end
