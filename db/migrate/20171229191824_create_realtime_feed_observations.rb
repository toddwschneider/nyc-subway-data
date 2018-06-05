class CreateRealtimeFeedObservations < ActiveRecord::Migration[5.1]
  def change
    create_table :realtime_feed_observations do |t|
      t.integer :feed_id, null: false
      t.timestamp :observed_at, null: false
      t.jsonb :data
      t.timestamp :processed_at
      t.timestamps
    end
    add_index :realtime_feed_observations, %i(feed_id observed_at), unique: true
  end
end
