class RealtimeFeedMapper
  MAPPING = {
    "1" => 1,
    "2" => 1,
    "3" => 1,
    "4" => 1,
    "5" => 1,
    "5X" => 1,
    "6" => 1,
    "6X" => 1,
    "7" => 51,
    "GS" => 1,
    "A" => 26,
    "B" => 21,
    "C" => 26,
    "D" => 21,
    "E" => 26,
    "F" => 21,
    "G" => 31,
    "J" => 36,
    "L" => 2,
    "M" => 21,
    "N" => 16,
    "Q" => 16,
    "R" => 16,
    "W" => 16,
    "Z" => 36,
    "SI" => 11
  }

  def map_routes_to_feeds
    MAPPING.each do |k, v|
      route = Route.find_by!(mta_id: k)
      feed = RealtimeFeed.find_or_create_by!(mta_id: v)

      route.realtime_feed = feed
      route.save!
    end
  end
end
