class CreateGtfsTables < ActiveRecord::Migration[5.1]
  def change
    create_table :agencies do |t|
      t.text :mta_id, null: false
      t.text :name
      t.text :url
      t.text :timezone
      t.text :language
      t.text :phone
      t.timestamps
    end
    add_index :agencies, :mta_id, unique: true

    create_table :calendars do |t|
      t.text :service_id, null: false
      t.boolean :monday, null: false
      t.boolean :tuesday, null: false
      t.boolean :wednesday, null: false
      t.boolean :thursday, null: false
      t.boolean :friday, null: false
      t.boolean :saturday, null: false
      t.boolean :sunday, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.timestamps
    end
    add_index :calendars, %i(service_id start_date end_date), unique: true

    create_table :calendar_dates do |t|
      t.text :service_id, null: false
      t.date :date, null: false
      t.integer :exception_type
      t.timestamps
    end
    add_index :calendar_dates, %i(service_id date), unique: true

    create_table :routes do |t|
      t.text :mta_id, null: false
      t.text :agency_mta_id, null: false
      t.text :short_name
      t.text :long_name
      t.text :description
      t.text :route_type
      t.text :url
      t.text :color
      t.text :text_color
      t.integer :realtime_feed_id
      t.timestamps
    end
    add_index :routes, :mta_id, unique: true

    create_table :shapes do |t|
      t.text :mta_id, null: false
      t.decimal :latitude
      t.decimal :longitude
      t.integer :sequence, null: false
      t.decimal :dist_traveled
      t.timestamps
    end
    add_index :shapes, %i(mta_id sequence), unique: true

    create_table :stop_times do |t|
      t.text :trip_mta_id, null: false
      t.text :arrival_time
      t.text :departure_time
      t.text :stop_mta_id, null: false
      t.integer :stop_sequence
      t.text :stop_headsign
      t.integer :pickup_type
      t.integer :drop_off_type
      t.decimal :shape_dist_traveled
      t.timestamps
    end
    add_index :stop_times, %i(trip_mta_id stop_mta_id), unique: true

    create_table :stops do |t|
      t.text :mta_id, null: false
      t.text :code
      t.text :name
      t.text :description
      t.decimal :latitude
      t.decimal :longitude
      t.text :zone_id
      t.text :url
      t.text :location_type
      t.text :parent_station
      t.timestamps
    end
    add_index :stops, :mta_id, unique: true
    add_index :stops, :parent_station

    create_table :transfers do |t|
      t.text :from_stop_mta_id, null: false
      t.text :to_stop_mta_id, null: false
      t.integer :transfer_type
      t.decimal :min_transfer_time
      t.timestamps
    end
    add_index :transfers,
      %i(from_stop_mta_id to_stop_mta_id),
      unique: true,
      name: "index_transfers_on_from_stop_and_top_stop"

    create_table :scheduled_trips do |t|
      t.text :mta_id, null: false
      t.text :route_mta_id, null: false
      t.text :service_id, null: false
      t.text :headsign
      t.integer :direction_id
      t.text :block_id
      t.text :shape_mta_id
      t.timestamps
    end
    add_index :scheduled_trips, :mta_id, unique: true
    add_index :scheduled_trips, :service_id
  end
end
