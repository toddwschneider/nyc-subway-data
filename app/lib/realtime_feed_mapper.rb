class RealtimeFeedMapper
  MAPPING = {
    "1" => [1, "gtfs"],
    "2" => [1, "gtfs"],
    "3" => [1, "gtfs"],
    "4" => [1, "gtfs"],
    "5" => [1, "gtfs"],
    "5X" => [1, "gtfs"],
    "6" => [1, "gtfs"],
    "6X" => [1, "gtfs"],
    "7" => [51, "gtfs-7"],
    "7X" => [51, "gtfs-7"],
    "GS" => [1, "gtfs"],
    "A" => [26, "gtfs-ace"],
    "B" => [21, "gtfs-bdfm"],
    "C" => [26, "gtfs-ace"],
    "D" => [21, "gtfs-bdfm"],
    "E" => [26, "gtfs-ace"],
    "F" => [21, "gtfs-bdfm"],
    "FS" => [26, "gtfs-ace"],
    "FX" => [21, "gtfs-bdfm"],
    "G" => [31, "gtfs-g"],
    "H" => [26, "gtfs-ace"],
    "J" => [36, "gtfs-jz"],
    "L" => [2, "gtfs-l"],
    "M" => [21, "gtfs-bdfm"],
    "N" => [16, "gtfs-nqrw"],
    "Q" => [16, "gtfs-nqrw"],
    "R" => [16, "gtfs-nqrw"],
    "W" => [16, "gtfs-nqrw"],
    "Z" => [36, "gtfs-jz"],
    "SI" => [11, "gtfs-si"]
  }

  def map_routes_to_feeds
    MAPPING.each do |k, ids|
      route = Route.find_by!(mta_id: k)
      feed = RealtimeFeed.find_or_create_by!(old_mta_id: ids.first, mta_id: ids.second)

      route.realtime_feed = feed
      route.save!
    end
  end
end
