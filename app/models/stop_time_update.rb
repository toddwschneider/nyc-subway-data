class StopTimeUpdate < ApplicationRecord
  validates :realtime_trip, :stop_mta_id, :observed_at, :observation_id,
    presence: true

  belongs_to :realtime_trip
  belongs_to :stop, foreign_key: :stop_mta_id, primary_key: :mta_id, optional: true
  belongs_to :observation, class_name: "RealtimeFeedObservation", optional: true

  delegate :route, to: :realtime_trip

  scope :assigned, -> { where(realtime_trip_is_assigned: true) }
  scope :not_assigned, -> { where(realtime_trip_is_assigned: false) }
end
