# Analysis scripts

Assorted SQL and R scripts to analyze the data once it's collected.

#### Prerequisites

Collect and process some subway data by running the main app for a while. You can also download some of my processed data from S3 (see below).

Install [R](https://www.r-project.org/) and [PostGIS](https://postgis.net/install/). You don't *really* need PostGIS, it's only used for convenience to determine which subway stops are in which neighborhoods/boroughs, but it's nice to have.

#### Scripts

`psql nyc_gtfs_development -f merge_trips.sql` tries to find cases where there are multiple records in the `realtime_trips` table that actually represent the same train, and then updates the `stop_time_updates` and `vehicle_positions` tables accordingly. It'd be nice if the MTA API always identified unique trains, but it doesn't, and sometimes various identifiers change from one minute to the next, so I don't know of any way to determine unique trains with 100% accuracy.

`psql nyc_gtfs_development -f subway_data_clean.sql` does the calculations that turn `stop_time_updates` into estimates of when each train stopped at each station. The basic idea is that train T is estimated to have stopped at stop S when S disappears from the list of T's upcoming stops, subject to the estimated stop time not being too different from the observation time.

`./create_stops_with_geo.sh` creates the `stops_with_geo` table, which adds neighborhood and borough information to the MTA's stops data. You can skip this if you don't have PostGIS, but you'll need to make a few modifications in analysis.R.

`analysis.R` uses the `subway_data_clean` table to do various calculations of expected wait times, station to station travel times, draw graphs, etc.

## Partial data on Amazon S3

The contents of the `subway_data_clean` table I used for my post are available for download from a requester pays Amazon S3 bucket:

https://s3.amazonaws.com/nyc-subway-data/subway_data_clean.csv.gz

[See here](https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html) for instructions on how to download from a requester pays S3 bucket. The data is from January 2018 to May 2018, and around 1 GB uncompressed.

Note that the dataset available on S3 is only part of the data used in the post.
