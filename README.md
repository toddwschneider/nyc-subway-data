# NYC Subway Data

A Rails app to collect data from the [MTA's real-time data feeds](http://datamine.mta.info/). Additional SQL and R analysis scripts/instructions are included in the `analysis/` subfolder.

Code used in support of the post "[Using Countdown Clock Data to Understand the New York City Subway](http://toddwschneider.com/posts/nyc-subway-data-analysis/)"

## Setup

Assumes Ruby, Rails, and PostgreSQL are all installed

1. Register for an MTA API key at http://datamine.mta.info/user/register
2. Copy the `.sample.env` file to `.env` in the project root, and edit it to set the `MTA_KEY` to the key you just obtained
3. `bundle exec rake db:setup` will create a database and populate it with the MTA's static [GTFS data](https://developers.google.com/transit/gtfs/examples/gtfs-feed), which is downloaded automatically from http://web.mta.info/developers/data/nyct/subway/google_transit.zip

Optionally, add `PROCESS_OBSERVATIONS_AFTER_CREATE=true` to the `.env` file if you want to process observations automatically after they are created. This is recommended in development, but you might not want to do it in production as it will cause your database's size to grow very quickly.

## Record data on a cron

You need to run 2 processes to record data:

- `bundle exec clockwork clock.rb`
- `bundle exec rake jobs:work`

The clock process queues up jobs every minute to ping the MTA's feeds, and the worker process makes the API requests and does the data processing. You can also run a single Foreman process with `bundle exec foreman start -f Procfile.clockplusworker`, which works on a $7 per month Heroku hobby dyno.

## Data structure

For an overview, check out:

- The [MTA's documentation](http://datamine.mta.info/sites/all/files/pdfs/GTFS-Realtime-NYC-Subway%20version%201%20dated%207%20Sep.pdf)
- The [GTFS Realtime](https://developers.google.com/transit/gtfs-realtime/) spec
- The [GTFS Static](https://developers.google.com/transit/gtfs/) spec

The API responses are stored as JSON in the `realtime_feed_observations` table. When a realtime observation is "processed", it is broken out into the `realtime_trips`, `stop_time_updates`, and `vehicle_positions` tables.

`realtime_trips` is supposed to contain one row for each unique train. In practice it probably overcounts trains, as the data is generally unreliable, trains don't have canonical IDs, and the various identifiers they do have sometimes change from minute to minute. The [MTA GTFS-realtime reference](http://datamine.mta.info/sites/all/files/pdfs/GTFS-Realtime-NYC-Subway%20version%201%20dated%207%20Sep.pdf) provides guidance on determining unique trains, but I used my own logic in the `RealtimeFeedObservation#find_or_create_realtime_trip_from_entity` method. Note that at analysis time, I attempted to merge duplicate records in the `realtime_trips` table, see `analysis/merge_trips.sql`. Also note that the MTA has a list of scheduled trips—populated in the `scheduled_trips` table—but the actual trips that show up in the `realtime_trips` table usually do not share IDs with the `scheduled_trips` records.

The `stop_time_updates` table includes, for each observed train, a list of its upcoming stops and their estimated arrival/departure times. This appears to be the information used on the subway platform countdown clocks.

The `vehicle_positions` table is supposed to include an estimate of each train's location at each observation time, but unfortunately in most cases the MTA does not provide the stop ID, only the stop sequence, and as far as I can tell there's no way to know for sure how to map from stop sequences to stop IDs. It's true that *most* trips from the same line have the same stop sequences, but there are enough cases where the total number of stops differ that it seemed like a bad idea to assume anything, which is why I used `stop_time_updates` to estimate actual stop times instead of `vehicle_positions`. It'd be nice if the MTA could supply stop IDs in their vehicle position entities...

## Questions/issues/contact

todd@toddwschneider.com, or open a GitHub issue
