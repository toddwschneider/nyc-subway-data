class RealtimeTrip < ApplicationRecord
  MTA_SUB_ID_REGEX = /^(\d{6}_\w{1,2}(?:\.{1,2}[NS])?)/i

  has_paper_trail on: %i(update destroy),
    ignore: %i(first_observed_at most_recently_observed_at)

  validates_presence_of :mta_id, :mta_sub_id, :start_date, :route_mta_id,
    :train_id, :train_sub_id, :direction, :origin_location,
    :destination_location, :most_recently_observed_at, :first_observed_at

  validates_inclusion_of :is_assigned, in: [true, false]

  belongs_to :route,
    foreign_key: :route_mta_id,
    primary_key: :mta_id,
    optional: true

  has_many :stop_time_updates
  has_many :stops, -> { distinct }, through: :stop_time_updates
  has_many :vehicle_positions
  has_many :alerts, primary_key: :mta_id, foreign_key: :realtime_trip_mta_id

  scope :assigned, -> { where(is_assigned: true) }
  scope :not_assigned, -> { where(is_assigned: false) }
  scope :south_or_brooklyn_bound, -> { where(direction: TransitRealtime::NyctTripDescriptor::Direction::SOUTH) }
  scope :north_or_manhattan_bound, -> { where(direction: TransitRealtime::NyctTripDescriptor::Direction::NORTH) }

  def is_not_assigned?
    !is_assigned?
  end

  def start_time
    since_midnight = mta_id.split("_").first.to_f / 100
    start_date.in_time_zone("America/New_York") + since_midnight.minutes
  end
end
