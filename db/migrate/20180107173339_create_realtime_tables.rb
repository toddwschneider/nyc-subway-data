class CreateRealtimeTables < ActiveRecord::Migration[5.1]
  def change
    create_table :realtime_trips do |t|
      t.string :mta_id, null: false
      t.string :mta_sub_id, null: false
      t.date :start_date, null: false
      t.string :route_mta_id, null: false
      t.string :train_id, null: false
      t.string :train_sub_id, null: false
      t.string :origin_location, null: false
      t.string :destination_location, null: false
      t.integer :direction, null: false
      t.boolean :is_assigned, null: false
      t.timestamp :first_observed_at, null: false
      t.timestamp :most_recently_observed_at, null: false
      t.timestamps
    end

    add_index :realtime_trips,
      %i(mta_sub_id start_date train_sub_id route_mta_id),
      unique: true,
      name: "index_realtime_trips_uniqueness"

    create_table :stop_time_updates do |t|
      t.integer :realtime_trip_id, null: false
      t.string :stop_mta_id, null: false
      t.timestamp :observed_at, null: false
      t.timestamp :arrival_time
      t.timestamp :departure_time
      t.integer :schedule_relationship
      t.string :scheduled_track
      t.string :actual_track
      t.boolean :realtime_trip_is_assigned
      t.integer :observation_id, null: false
    end

    add_index :stop_time_updates,
      %i(realtime_trip_id stop_mta_id observation_id),
      unique: true,
      name: "index_stop_time_updates_on_trip_stop_and_observation"

    create_table :vehicle_positions do |t|
      t.integer :realtime_trip_id, null: false
      t.timestamp :observed_at, null: false
      t.integer :current_stop_sequence
      t.integer :current_status
      t.string :stop_mta_id
      t.boolean :realtime_trip_is_assigned
      t.integer :observation_id, null: false
    end

    add_index :vehicle_positions,
      %i(realtime_trip_id observation_id),
      unique: true

    create_table :alerts do |t|
      t.string :realtime_trip_mta_id, null: false
      t.boolean :realtime_trip_is_assigned
      t.text :header_text
      t.timestamp :observed_at, null: false
      t.integer :observation_id, null: false
    end

    add_index :alerts, %i(realtime_trip_mta_id observation_id), unique: true
  end
end
