class ActiveSupport::TimeWithZone
  def nyc
    in_time_zone("America/New_York")
  end
end
