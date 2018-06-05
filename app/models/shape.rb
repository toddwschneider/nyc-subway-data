class Shape < ApplicationRecord
  validates :mta_id, presence: true, uniqueness: {scope: :sequence}
  validates :sequence, presence: true

  belongs_to :trip, foreign_key: :mta_id, primary_key: :shape_mta_id
end
