class RealtimeFeedObservation < ApplicationRecord
  validates :feed, :observed_at, presence: true

  belongs_to :feed, class_name: "RealtimeFeed"

  has_many :stop_time_updates, foreign_key: :observation_id
  has_many :vehicle_positions, foreign_key: :observation_id
  has_many :alerts, foreign_key: :observation_id

  scope :processed, -> { where.not(processed_at: nil) }
  scope :unprocessed, -> { where(processed_at: nil) }

  def encoded
    @encoded ||= TransitRealtime::FeedMessage.encode(data)
  end

  def as_proto
    @as_proto ||= TransitRealtime::FeedMessage.decode(encoded)
  end

  def process_entities
    as_proto.entity.each { |e| process_entity(e) }

    self.processed_at = Time.zone.now
    save!
  end

  def process_entity(entity)
    if entity.trip_update
      process_trip_update(entity.trip_update)
    elsif entity.vehicle
      process_vehicle_position(entity.vehicle)
    elsif entity.alert
      process_alert(entity.alert)
    end
  end

  def process_trip_update(entity)
    realtime_trip = find_or_create_realtime_trip_from_entity(entity.trip)
    return unless realtime_trip.present?

    entity.stop_time_update.each do |stu_entity|
      arrival_time = stu_entity.arrival&.time
      departure_time = stu_entity.departure&.time

      begin
        realtime_trip.
          stop_time_updates.
          create do |stu|
            stu.stop_mta_id = stu_entity.stop_id
            stu.observation_id = id
            stu.observed_at = observed_at
            stu.arrival_time = (Time.zone.at(arrival_time) if arrival_time)
            stu.departure_time = (Time.zone.at(departure_time) if departure_time)
            stu.schedule_relationship = stu_entity.schedule_relationship
            stu.scheduled_track = stu_entity.nyct_stop_time_update&.scheduled_track
            stu.actual_track = stu_entity.nyct_stop_time_update&.actual_track
            stu.realtime_trip_is_assigned = entity.trip.nyct_trip_descriptor&.is_assigned
          end
      rescue ActiveRecord::RecordNotUnique
      end
    end
  end

  def process_vehicle_position(entity)
    realtime_trip = find_or_create_realtime_trip_from_entity(entity.trip)
    return unless realtime_trip.present?

    begin
      realtime_trip.
        vehicle_positions.
        create do |v|
          v.observation_id = id
          v.observed_at = Time.zone.at(entity.timestamp)
          v.realtime_trip_is_assigned = entity.trip&.nyct_trip_descriptor&.is_assigned
          v.current_stop_sequence = entity.current_stop_sequence
          v.current_status = entity.current_status
          v.stop_mta_id = entity.stop_id.presence
        end
    rescue ActiveRecord::RecordNotUnique
    end
  end

  def process_alert(entity)
    header_text = entity.header_text&.translation&.first&.text

    entity.informed_entity.each do |informed_entity|
      trip = informed_entity.trip
      next unless trip.nyct_trip_descriptor&.is_assigned || include_unassigned_trips?

      begin
        alerts.create do |a|
          a.realtime_trip_mta_id = trip.trip_id
          a.observed_at = observed_at
          a.header_text = header_text
          a.realtime_trip_is_assigned = trip.nyct_trip_descriptor&.is_assigned
        end
      rescue ActiveRecord::RecordNotUnique
      end
    end
  end

  def find_or_create_realtime_trip_from_entity(trip_entity)
    return unless trip_entity.route_id.present?
    return unless nyct = trip_entity.nyct_trip_descriptor
    return unless nyct.is_assigned || include_unassigned_trips?

    mta_sub_id = trip_entity.trip_id[RealtimeTrip::MTA_SUB_ID_REGEX, 1]
    train_sub_id = nyct.train_id.last(7).gsub(" ", "")
    origin_location = train_sub_id.split("/").first
    destination_location = train_sub_id.split("/").last

    realtime_trip = RealtimeTrip.find_or_create_by!(
      mta_sub_id: mta_sub_id,
      start_date: trip_entity.start_date,
      route_mta_id: trip_entity.route_id,
      train_sub_id: train_sub_id
    ) do |t|
      t.first_observed_at = observed_at
      t.most_recently_observed_at = observed_at
      t.mta_id = trip_entity.trip_id
      t.train_id = nyct.train_id
      t.is_assigned = nyct.is_assigned
      t.direction = nyct.direction
      t.origin_location = origin_location
      t.destination_location = destination_location
    end

    if observed_at < realtime_trip.first_observed_at
      realtime_trip.first_observed_at = observed_at
      realtime_trip.save!
    end

    if observed_at > realtime_trip.most_recently_observed_at
      realtime_trip.most_recently_observed_at = observed_at
      realtime_trip.mta_id = trip_entity.trip_id
      realtime_trip.train_id = nyct.train_id
      realtime_trip.is_assigned = nyct.is_assigned
      realtime_trip.direction = nyct.direction
      realtime_trip.origin_location = origin_location
      realtime_trip.destination_location = destination_location

      realtime_trip.save!
    end

    realtime_trip
  end

  class << self
    def process_observation(observation_id)
      return if observation_id.blank?

      find(observation_id).process_entities
    end
    handle_asynchronously :process_observation, priority: 100

    def process_all(observed_after: nil, observed_before: nil, reprocess_already_processed: false)
      scoped = select(:id)

      scoped = scoped.where("observed_at > ?", observed_after) if observed_after
      scoped = scoped.where("observed_at < ?", observed_before) if observed_before
      scoped = scoped.unprocessed unless reprocess_already_processed

      scoped.find_each { |o| process_observation(o.id) }
    end
    handle_asynchronously :process_all, priority: 50
  end

  def process_after_create?
    ENV["PROCESS_OBSERVATIONS_AFTER_CREATE"] == "true"
  end

  def include_unassigned_trips?
    ENV["INCLUDE_UNASSIGNED_TRIPS"] == "true"
  end
end
