class Alert < ApplicationRecord
  validates :realtime_trip_mta_id, :observed_at, :observation_id, presence: true

  belongs_to :realtime_trip,
    foreign_key: :realtime_trip_mta_id,
    primary_key: :mta_id,
    optional: true

  belongs_to :observation, class_name: "RealtimeFeedObservation", optional: true
end
