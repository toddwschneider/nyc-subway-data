class RealtimeFeed < ApplicationRecord
  HISTORICAL_DATA_BASE_URL = "https://datamine-history.s3.amazonaws.com"
  HISTORICAL_DATA_PREFIXES = {
    1 => "gtfs",
    2 => "gtfs-l"
  }

  validates :mta_id, presence: true, uniqueness: true

  has_many :observations,
    class_name: "RealtimeFeedObservation",
    foreign_key: :feed_id

  has_many :routes

  def url
    query = {key: ENV.fetch("MTA_KEY"), feed_id: mta_id}.to_query
    "http://datamine.mta.info/mta_esi.php?#{query}"
  end

  def fetch_data
    data = HTTParty.get(url).body
    TransitRealtime::FeedMessage.decode(data)
  end

  def record_observation
    data = fetch_data

    return if data.entity.blank?

    obs = begin
      observations.create do |o|
        o.observed_at = Time.zone.at(data.header.timestamp)
        o.data = data
      end
    rescue ActiveRecord::RecordNotUnique
    end

    if obs&.process_after_create?
      RealtimeFeedObservation.process_observation(obs&.id)
    end
  end
  handle_asynchronously :record_observation, priority: 0

  class << self
    def record_observations_for_all
      find_each(&:record_observation)
    end
    handle_asynchronously :record_observations_for_all, priority: 10
  end

  def backfill_historical_realtime_data(date:, hours: (0..23))
    prefix = HISTORICAL_DATA_PREFIXES[mta_id]
    raise "no historical data available" unless prefix.present?

    hours = hours.map { |h| h.to_s.rjust(2, "0") }
    minutes = (1..56).step(5).map { |m| m.to_s.rjust(2, "0") }

    hours.product(minutes).each do |hour, minute|
      url = "#{HISTORICAL_DATA_BASE_URL}/#{prefix}-#{date.to_date}-#{hour}-#{minute}"

      request = HTTParty.get(url)
      next unless request.ok?

      data = TransitRealtime::FeedMessage.decode(request.body)

      begin
        observations.create do |o|
          o.observed_at = Time.zone.at(data.header.timestamp)
          o.data = data
        end
      rescue ActiveRecord::RecordNotUnique
      end
    end
  end
  handle_asynchronously :backfill_historical_realtime_data, priority: 20
end
