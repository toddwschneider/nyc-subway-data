class StopTime < ApplicationRecord
  validates :trip_mta_id, presence: true, uniqueness: {scope: :stop_mta_id}
  validates :stop_mta_id, presence: true

  belongs_to :scheduled_trip, foreign_key: :trip_mta_id, primary_key: :mta_id
  belongs_to :stop, foreign_key: :stop_mta_id, primary_key: :mta_id
end
