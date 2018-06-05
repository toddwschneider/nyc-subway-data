class ScheduledTrip < ApplicationRecord
  validates :mta_id, presence: true, uniqueness: true

  belongs_to :route, foreign_key: :route_mta_id, primary_key: :mta_id
  belongs_to :calendar, foreign_key: :service_id, primary_key: :service_id

  has_many :stop_times,
    -> { order(:stop_sequence) },
    primary_key: :mta_id,
    foreign_key: :trip_mta_id

  has_many :stops, through: :stop_times

  has_many :shapes, primary_key: :shape_mta_id, foreign_key: :mta_id

  scope :south_or_brooklyn_bound, -> { where(direction: TransitRealtime::NyctTripDescriptor::Direction::SOUTH) }
  scope :north_or_manhattan_bound, -> { where(direction: TransitRealtime::NyctTripDescriptor::Direction::NORTH) }
end
