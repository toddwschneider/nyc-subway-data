# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_04_04_140412) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "agencies", force: :cascade do |t|
    t.text "mta_id", null: false
    t.text "name"
    t.text "url"
    t.text "timezone"
    t.text "language"
    t.text "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["mta_id"], name: "index_agencies_on_mta_id", unique: true
  end

  create_table "alerts", force: :cascade do |t|
    t.string "realtime_trip_mta_id", null: false
    t.boolean "realtime_trip_is_assigned"
    t.text "header_text"
    t.datetime "observed_at", null: false
    t.integer "observation_id", null: false
    t.index ["realtime_trip_mta_id", "observation_id"], name: "index_alerts_on_realtime_trip_mta_id_and_observation_id", unique: true
  end

  create_table "calendar_dates", force: :cascade do |t|
    t.text "service_id", null: false
    t.date "date", null: false
    t.integer "exception_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["service_id", "date"], name: "index_calendar_dates_on_service_id_and_date", unique: true
  end

  create_table "calendars", force: :cascade do |t|
    t.text "service_id", null: false
    t.boolean "monday", null: false
    t.boolean "tuesday", null: false
    t.boolean "wednesday", null: false
    t.boolean "thursday", null: false
    t.boolean "friday", null: false
    t.boolean "saturday", null: false
    t.boolean "sunday", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["service_id", "start_date", "end_date"], name: "index_calendars_on_service_id_and_start_date_and_end_date", unique: true
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "realtime_feed_observations", force: :cascade do |t|
    t.integer "feed_id", null: false
    t.datetime "observed_at", null: false
    t.jsonb "data"
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feed_id", "observed_at"], name: "index_realtime_feed_observations_on_feed_id_and_observed_at", unique: true
  end

  create_table "realtime_feeds", force: :cascade do |t|
    t.integer "old_mta_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "mta_id", null: false
    t.index ["mta_id"], name: "index_realtime_feeds_on_mta_id", unique: true
    t.index ["old_mta_id"], name: "index_realtime_feeds_on_old_mta_id", unique: true
  end

  create_table "realtime_trips", force: :cascade do |t|
    t.string "mta_id", null: false
    t.string "mta_sub_id", null: false
    t.date "start_date", null: false
    t.string "route_mta_id", null: false
    t.string "train_id", null: false
    t.string "train_sub_id", null: false
    t.string "origin_location", null: false
    t.string "destination_location", null: false
    t.integer "direction", null: false
    t.boolean "is_assigned", null: false
    t.datetime "first_observed_at", null: false
    t.datetime "most_recently_observed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["mta_sub_id", "start_date", "train_sub_id", "route_mta_id"], name: "index_realtime_trips_uniqueness", unique: true
  end

  create_table "routes", force: :cascade do |t|
    t.text "mta_id", null: false
    t.text "agency_mta_id", null: false
    t.text "short_name"
    t.text "long_name"
    t.text "description"
    t.text "route_type"
    t.text "url"
    t.text "color"
    t.text "text_color"
    t.integer "realtime_feed_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["mta_id"], name: "index_routes_on_mta_id", unique: true
  end

  create_table "scheduled_trips", force: :cascade do |t|
    t.text "mta_id", null: false
    t.text "route_mta_id", null: false
    t.text "service_id", null: false
    t.text "headsign"
    t.integer "direction_id"
    t.text "block_id"
    t.text "shape_mta_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["mta_id"], name: "index_scheduled_trips_on_mta_id", unique: true
    t.index ["service_id"], name: "index_scheduled_trips_on_service_id"
  end

  create_table "shapes", force: :cascade do |t|
    t.text "mta_id", null: false
    t.decimal "latitude"
    t.decimal "longitude"
    t.integer "sequence", null: false
    t.decimal "dist_traveled"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["mta_id", "sequence"], name: "index_shapes_on_mta_id_and_sequence", unique: true
  end

  create_table "stop_time_updates", force: :cascade do |t|
    t.integer "realtime_trip_id", null: false
    t.string "stop_mta_id", null: false
    t.datetime "observed_at", null: false
    t.datetime "arrival_time"
    t.datetime "departure_time"
    t.integer "schedule_relationship"
    t.string "scheduled_track"
    t.string "actual_track"
    t.boolean "realtime_trip_is_assigned"
    t.integer "observation_id", null: false
    t.index ["realtime_trip_id", "stop_mta_id", "observation_id"], name: "index_stop_time_updates_on_trip_stop_and_observation", unique: true
  end

  create_table "stop_times", force: :cascade do |t|
    t.text "trip_mta_id", null: false
    t.text "arrival_time"
    t.text "departure_time"
    t.text "stop_mta_id", null: false
    t.integer "stop_sequence"
    t.text "stop_headsign"
    t.integer "pickup_type"
    t.integer "drop_off_type"
    t.decimal "shape_dist_traveled"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["trip_mta_id", "stop_mta_id"], name: "index_stop_times_on_trip_mta_id_and_stop_mta_id", unique: true
  end

  create_table "stops", force: :cascade do |t|
    t.text "mta_id", null: false
    t.text "code"
    t.text "name"
    t.text "description"
    t.decimal "latitude"
    t.decimal "longitude"
    t.text "zone_id"
    t.text "url"
    t.text "location_type"
    t.text "parent_station"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["mta_id"], name: "index_stops_on_mta_id", unique: true
    t.index ["parent_station"], name: "index_stops_on_parent_station"
  end

  create_table "transfers", force: :cascade do |t|
    t.text "from_stop_mta_id", null: false
    t.text "to_stop_mta_id", null: false
    t.integer "transfer_type"
    t.decimal "min_transfer_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["from_stop_mta_id", "to_stop_mta_id"], name: "index_transfers_on_from_stop_and_top_stop", unique: true
  end

  create_table "vehicle_positions", force: :cascade do |t|
    t.integer "realtime_trip_id", null: false
    t.datetime "observed_at", null: false
    t.integer "current_stop_sequence"
    t.integer "current_status"
    t.string "stop_mta_id"
    t.boolean "realtime_trip_is_assigned"
    t.integer "observation_id", null: false
    t.index ["realtime_trip_id", "observation_id"], name: "index_vehicle_positions_on_realtime_trip_id_and_observation_id", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.jsonb "object"
    t.jsonb "object_changes"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

end
