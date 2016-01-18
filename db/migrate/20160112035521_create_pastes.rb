class CreatePastes < ActiveRecord::Migration
  def change
    create_table :pastes do |t|
      t.string :title
      t.string :language_id
      t.text :text

      t.timestamps null: false
    end
  end
end
