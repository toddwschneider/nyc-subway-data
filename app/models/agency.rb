class Agency < ApplicationRecord
  validates :mta_id, presence: true, uniqueness: true

  has_many :routes, primary_key: :mta_id, foreign_key: :agency_mta_id
end
