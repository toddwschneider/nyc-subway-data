class CreateFeeds < ActiveRecord::Migration[5.1]
  def change
    create_table :realtime_feeds do |t|
      t.integer :mta_id, null: false
      t.timestamps
    end
    add_index :realtime_feeds, :mta_id, unique: true
  end
end
