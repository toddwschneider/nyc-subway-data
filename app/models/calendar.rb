class Calendar < ApplicationRecord
  validates :service_id,
    presence: true,
    uniqueness: {scope: %i(start_date end_date)}

  validates :start_date, :end_date, presence: true

  has_many :scheduled_trips, primary_key: :service_id, foreign_key: :service_id
end
