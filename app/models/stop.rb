class Stop < ApplicationRecord
  validates :mta_id, presence: true, uniqueness: true

  has_many :stop_times, primary_key: :mta_id, foreign_key: :stop_mta_id
  has_many :scheduled_trips, through: :stop_times
  has_many :routes, -> { distinct }, through: :scheduled_trips

  has_many :stop_time_updates, primary_key: :mta_id, foreign_key: :stop_mta_id
  has_many :realtime_trips, -> { distinct }, through: :stop_time_updates

  has_many :transfers_as_from_stop,
    class_name: "Transfer",
    primary_key: :mta_id,
    foreign_key: :from_stop_mta_id

  has_many :transfers_as_to_stop,
    class_name: "Transfer",
    primary_key: :mta_id,
    foreign_key: :to_stop_mta_id

  belongs_to :parent_stop,
    class_name: "Stop",
    foreign_key: :parent_station,
    primary_key: :mta_id,
    optional: true

  has_many :child_stops,
    class_name: "Stop",
    primary_key: :mta_id,
    foreign_key: :parent_station
end
