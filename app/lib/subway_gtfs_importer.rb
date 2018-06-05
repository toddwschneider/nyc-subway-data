class SubwayGtfsImporter
  MTA_URL = "http://web.mta.info/developers/data/nyct/subway/google_transit.zip"

  COPY_INSTRUCTIONS = [
    {
      table_name: "agencies",
      file_name: "agency.txt",
      copy_schema: "mta_id, name, url, timezone, language, phone, created_at, updated_at"
    },
    {
      table_name: "calendars",
      file_name: "calendar.txt",
      copy_schema: "service_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, start_date, end_date, created_at, updated_at"
    },
    {
      table_name: "calendar_dates",
      file_name: "calendar_dates.txt",
      copy_schema: "service_id, date, exception_type, created_at, updated_at"
    },
    {
      table_name: "routes",
      file_name: "routes.txt",
      copy_schema: "mta_id, agency_mta_id, short_name, long_name, description, route_type, url, color, text_color, created_at, updated_at"
    },
    {
      table_name: "shapes",
      file_name: "shapes.txt",
      copy_schema: "mta_id, latitude, longitude, sequence, dist_traveled, created_at, updated_at"
    },
    {
      table_name: "stop_times",
      file_name: "stop_times.txt",
      copy_schema: "trip_mta_id, arrival_time, departure_time, stop_mta_id, stop_sequence, stop_headsign, pickup_type, drop_off_type, shape_dist_traveled, created_at, updated_at"
    },
    {
      table_name: "stops",
      file_name: "stops.txt",
      copy_schema: "mta_id, code, name, description, latitude, longitude, zone_id, url, location_type, parent_station, created_at, updated_at"
    },
    {
      table_name: "transfers",
      file_name: "transfers.txt",
      copy_schema: "from_stop_mta_id, to_stop_mta_id, transfer_type, min_transfer_time, created_at, updated_at"
    },
    {
      table_name: "scheduled_trips",
      file_name: "trips.txt",
      copy_schema: "route_mta_id, service_id, mta_id, headsign, direction_id, block_id, shape_mta_id, created_at, updated_at"
    }
  ]

  def import!
    encoder = PG::TextEncoder::CopyRow.new

    COPY_INSTRUCTIONS.each do |h|
      klass = h.fetch(:table_name).classify.constantize

      if klass.count > 0
        puts "#{h.fetch(:table_name)} already has rows in it; skipping COPY"
        next
      end

      now = Time.zone.now

      sql_statement = <<-SQL
        COPY #{h.fetch(:table_name)}
        (#{h.fetch(:copy_schema)})
        FROM stdin;
      SQL

      rows = data.fetch(h.fetch(:file_name)).drop(1)

      raw_db_connection.copy_data(sql_statement, encoder) do
        rows.each do |row|
          raw_db_connection.put_copy_data(row + [now, now])
        end
      end

      puts "#{h.fetch(:table_name)}: copied #{rows.size}"
    end
  end

  def raw_data
    return @raw_data if @raw_data
    puts "Downloading data from #{MTA_URL}"
    @raw_data = HTTParty.get(MTA_URL).body
  end

  def data
    return @data if @data

    require 'csv'
    contents = {}
    Zip::InputStream.open(StringIO.new(raw_data)) do |io|
      while entry = io.get_next_entry
        contents[entry.name] = CSV.parse(io.read)
      end
    end

    @data = contents
  end

  def raw_db_connection
    ApplicationRecord.connection.raw_connection
  end
end
