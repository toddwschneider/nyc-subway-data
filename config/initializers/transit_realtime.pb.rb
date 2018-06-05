module TransitRealtime
  ::Protobuf::Optionable.inject(self) { ::Google::Protobuf::FileOptions }

  class FeedMessage < ::Protobuf::Message; end

  class FeedHeader < ::Protobuf::Message
    class Incrementality < ::Protobuf::Enum
      define :FULL_DATASET, 0
      define :DIFFERENTIAL, 1
    end
  end

  class FeedEntity < ::Protobuf::Message; end

  class TripUpdate < ::Protobuf::Message
    class StopTimeEvent < ::Protobuf::Message; end

    class StopTimeUpdate < ::Protobuf::Message
      class ScheduleRelationship < ::Protobuf::Enum
        define :SCHEDULED, 0
        define :SKIPPED, 1
        define :NO_DATA, 2
      end
    end
  end

  class VehiclePosition < ::Protobuf::Message
    class VehicleStopStatus < ::Protobuf::Enum
      define :INCOMING_AT, 0
      define :STOPPED_AT, 1
      define :IN_TRANSIT_TO, 2
    end

    class CongestionLevel < ::Protobuf::Enum
      define :UNKNOWN_CONGESTION_LEVEL, 0
      define :RUNNING_SMOOTHLY, 1
      define :STOP_AND_GO, 2
      define :CONGESTION, 3
      define :SEVERE_CONGESTION, 4
    end

    class OccupancyStatus < ::Protobuf::Enum
      define :EMPTY, 0
      define :MANY_SEATS_AVAILABLE, 1
      define :FEW_SEATS_AVAILABLE, 2
      define :STANDING_ROOM_ONLY, 3
      define :CRUSHED_STANDING_ROOM_ONLY, 4
      define :FULL, 5
      define :NOT_ACCEPTING_PASSENGERS, 6
    end
  end

  class Alert < ::Protobuf::Message
    class Cause < ::Protobuf::Enum
      define :UNKNOWN_CAUSE, 1
      define :OTHER_CAUSE, 2
      define :TECHNICAL_PROBLEM, 3
      define :STRIKE, 4
      define :DEMONSTRATION, 5
      define :ACCIDENT, 6
      define :HOLIDAY, 7
      define :WEATHER, 8
      define :MAINTENANCE, 9
      define :CONSTRUCTION, 10
      define :POLICE_ACTIVITY, 11
      define :MEDICAL_EMERGENCY, 12
    end

    class Effect < ::Protobuf::Enum
      define :NO_SERVICE, 1
      define :REDUCED_SERVICE, 2
      define :SIGNIFICANT_DELAYS, 3
      define :DETOUR, 4
      define :ADDITIONAL_SERVICE, 5
      define :MODIFIED_SERVICE, 6
      define :OTHER_EFFECT, 7
      define :UNKNOWN_EFFECT, 8
      define :STOP_MOVED, 9
    end
  end

  class TimeRange < ::Protobuf::Message; end

  class Position < ::Protobuf::Message; end

  class TripDescriptor < ::Protobuf::Message
    class ScheduleRelationship < ::Protobuf::Enum
      define :SCHEDULED, 0
      define :ADDED, 1
      define :UNSCHEDULED, 2
      define :CANCELED, 3
    end
  end

  class VehicleDescriptor < ::Protobuf::Message; end

  class EntitySelector < ::Protobuf::Message; end

  class TranslatedString < ::Protobuf::Message
    class Translation < ::Protobuf::Message; end
  end

  class TripReplacementPeriod < ::Protobuf::Message; end

  class NyctFeedHeader < ::Protobuf::Message; end

  class NyctTripDescriptor < ::Protobuf::Message
    class Direction < ::Protobuf::Enum
      define :NORTH, 1
      define :EAST, 2
      define :SOUTH, 3
      define :WEST, 4
    end
  end

  class NyctStopTimeUpdate < ::Protobuf::Message; end

  set_option :java_package, "com.google.transit.realtime"

  class FeedMessage
    required ::TransitRealtime::FeedHeader, :header, 1
    repeated ::TransitRealtime::FeedEntity, :entity, 2
    extensions 1000...2000
  end

  class FeedHeader
    required :string, :gtfs_realtime_version, 1
    optional ::TransitRealtime::FeedHeader::Incrementality, :incrementality, 2, default: ::TransitRealtime::FeedHeader::Incrementality::FULL_DATASET
    optional :uint64, :timestamp, 3
    optional ::TransitRealtime::NyctFeedHeader, :".nyct_feed_header", 1001, extension: true
    extensions 1000...2000
  end

  class FeedEntity
    required :string, :id, 1
    optional :bool, :is_deleted, 2, default: false
    optional ::TransitRealtime::TripUpdate, :trip_update, 3
    optional ::TransitRealtime::VehiclePosition, :vehicle, 4
    optional ::TransitRealtime::Alert, :alert, 5
    extensions 1000...2000
  end

  class TripUpdate
    class StopTimeEvent
      optional :int32, :delay, 1
      optional :int64, :time, 2
      optional :int32, :uncertainty, 3
      extensions 1000...2000
    end

    class StopTimeUpdate
      optional :uint32, :stop_sequence, 1
      optional :string, :stop_id, 4
      optional ::TransitRealtime::TripUpdate::StopTimeEvent, :arrival, 2
      optional ::TransitRealtime::TripUpdate::StopTimeEvent, :departure, 3
      optional ::TransitRealtime::TripUpdate::StopTimeUpdate::ScheduleRelationship, :schedule_relationship, 5, default: ::TransitRealtime::TripUpdate::StopTimeUpdate::ScheduleRelationship::SCHEDULED
      optional ::TransitRealtime::NyctStopTimeUpdate, :".nyct_stop_time_update", 1001, extension: true
      extensions 1000...2000
    end

    required ::TransitRealtime::TripDescriptor, :trip, 1
    optional ::TransitRealtime::VehicleDescriptor, :vehicle, 3
    repeated ::TransitRealtime::TripUpdate::StopTimeUpdate, :stop_time_update, 2
    optional :uint64, :timestamp, 4
    optional :int32, :delay, 5
    extensions 1000...2000
  end

  class VehiclePosition
    optional ::TransitRealtime::TripDescriptor, :trip, 1
    optional ::TransitRealtime::VehicleDescriptor, :vehicle, 8
    optional ::TransitRealtime::Position, :position, 2
    optional :uint32, :current_stop_sequence, 3
    optional :string, :stop_id, 7
    optional ::TransitRealtime::VehiclePosition::VehicleStopStatus, :current_status, 4, default: ::TransitRealtime::VehiclePosition::VehicleStopStatus::IN_TRANSIT_TO
    optional :uint64, :timestamp, 5
    optional ::TransitRealtime::VehiclePosition::CongestionLevel, :congestion_level, 6
    optional ::TransitRealtime::VehiclePosition::OccupancyStatus, :occupancy_status, 9
    extensions 1000...2000
  end

  class Alert
    repeated ::TransitRealtime::TimeRange, :active_period, 1
    repeated ::TransitRealtime::EntitySelector, :informed_entity, 5
    optional ::TransitRealtime::Alert::Cause, :cause, 6, default: ::TransitRealtime::Alert::Cause::UNKNOWN_CAUSE
    optional ::TransitRealtime::Alert::Effect, :effect, 7, default: ::TransitRealtime::Alert::Effect::UNKNOWN_EFFECT
    optional ::TransitRealtime::TranslatedString, :url, 8
    optional ::TransitRealtime::TranslatedString, :header_text, 10
    optional ::TransitRealtime::TranslatedString, :description_text, 11
    extensions 1000...2000
  end

  class TimeRange
    optional :uint64, :start, 1
    optional :uint64, :end, 2
    extensions 1000...2000
  end

  class Position
    required :float, :latitude, 1
    required :float, :longitude, 2
    optional :float, :bearing, 3
    optional :double, :odometer, 4
    optional :float, :speed, 5
    extensions 1000...2000
  end

  class TripDescriptor
    optional :string, :trip_id, 1
    optional :string, :route_id, 5
    optional :uint32, :direction_id, 6
    optional :string, :start_time, 2
    optional :string, :start_date, 3
    optional ::TransitRealtime::TripDescriptor::ScheduleRelationship, :schedule_relationship, 4
    extensions 1000...2000
    optional ::TransitRealtime::NyctTripDescriptor, :".nyct_trip_descriptor", 1001, extension: true
  end

  class VehicleDescriptor
    optional :string, :id, 1
    optional :string, :label, 2
    optional :string, :license_plate, 3
    extensions 1000...2000
  end

  class EntitySelector
    optional :string, :agency_id, 1
    optional :string, :route_id, 2
    optional :int32, :route_type, 3
    optional ::TransitRealtime::TripDescriptor, :trip, 4
    optional :string, :stop_id, 5
    extensions 1000...2000
  end

  class TranslatedString
    class Translation
      required :string, :text, 1
      optional :string, :language, 2
      extensions 1000...2000
    end

    repeated ::TransitRealtime::TranslatedString::Translation, :translation, 1
    extensions 1000...2000
  end

  class TripReplacementPeriod
    optional :string, :route_id, 1
    optional ::TransitRealtime::TimeRange, :replacement_period, 2
  end

  class NyctFeedHeader
    required :string, :nyct_subway_version, 1
    repeated ::TransitRealtime::TripReplacementPeriod, :trip_replacement_period, 2
  end

  class NyctTripDescriptor
    optional :string, :train_id, 1
    optional :bool, :is_assigned, 2
    optional ::TransitRealtime::NyctTripDescriptor::Direction, :direction, 3
  end

  class NyctStopTimeUpdate
    optional :string, :scheduled_track, 1
    optional :string, :actual_track, 2
  end
end
