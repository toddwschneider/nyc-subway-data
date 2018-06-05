class CalendarDate < ApplicationRecord
  validates :service_id,
    presence: true,
    uniqueness: {scope: :date}

  validates :date, presence: true
end
