class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :billetto_event_id, null: false
      t.string :title, null: false
      t.text :description
      t.datetime :starts_at, null: false
      t.datetime :ends_at
      t.text :image_url
      t.text :billetto_url

      t.timestamps

      t.index :billetto_event_id, unique: true
      t.index [ :starts_at, :id ]
    end
  end
end
