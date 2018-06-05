class Transfer < ApplicationRecord
  validates :from_stop_mta_id,
    presence: true,
    uniqueness: {scope: :to_stop_mta_id}

  validates :to_stop_mta_id, presence: true

  belongs_to :from_stop,
    class_name: "Stop",
    foreign_key: :from_stop_mta_id,
    primary_key: :mta_id

  belongs_to :to_stop,
    class_name: "Stop",
    foreign_key: :to_stop_mta_id,
    primary_key: :mta_id
end
