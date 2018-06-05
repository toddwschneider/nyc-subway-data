class Route < ApplicationRecord
  validates :mta_id, presence: true, uniqueness: true
  validates :agency_mta_id, presence: true

  belongs_to :agency, foreign_key: :agency_mta_id, primary_key: :mta_id
  belongs_to :realtime_feed

  has_many :scheduled_trips, primary_key: :mta_id, foreign_key: :route_mta_id
  has_many :realtime_trips, primary_key: :mta_id, foreign_key: :route_mta_id
end
