class CreateEvents < ActiveRecord::Migration[5.1]
  def change
    create_table :events do |t|
      t.string :event_feed_name
      t.string :name
      t.text :description, :summary
      t.string :identifier
      t.string :venue
      t.string :image
      t.timestamp :start_time
      t.timestamp :end_time

      t.jsonb :feed_response

      t.timestamps
    end
  end
end
