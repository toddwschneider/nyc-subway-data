source("support_scripts/helpers.R")

stops = query("
  SELECT mta_id, name, borough, latitude, longitude, zone
  FROM stops_with_geo
")

routes = query("SELECT mta_id, long_name, '#' || color AS color FROM routes") %>%
  mutate(color = case_when(
    mta_id %in% c("FS", "H") ~ "#808183",
    mta_id == "SI" ~ "#053159",
    TRUE ~ color
  ))

shuttle_routes = c("GS", "FS", "H")
staten_island_routes = c("SI", "SS")

subway_data = query("SELECT * FROM subway_data_clean") %>%
  mutate(
    wday = wday(departure_time),
    weekend = wday %in% c(1, 7),
    hour = hour(departure_time)
  )

# expected wait times
wait_time_distribution = function(filters = quos(route_mta_id == "6", !weekend)) {
  filtered_data = filter(subway_data, !!!filters)

  if (nrow(filtered_data) == 0) return(tibble())

  filtered_data %>%
    count(seconds_until_next_departure) %>%
    rename("t" = "seconds_until_next_departure") %>%
    complete(t = 1:max(t), fill = list(n = 0)) %>%
    arrange(desc(t)) %>%
    mutate(cum_n = cumsum(n)) %>%
    arrange(t) %>%
    mutate(
      pdf = cum_n / sum(cum_n),
      cdf = cumsum(pdf)
    ) %>%
    select(wait_time = t, pdf, cdf, cum_n)
}

wait_time_percentiles = function(filters = quos(route_mta_id == "6", !weekend),
                                 percentiles = c(0.1, 0.25, 0.5, 0.75, 0.9)) {
  empirical_distribution = wait_time_distribution(filters = filters)

  if (nrow(empirical_distribution) == 0) {
    return(tibble(percentile = percentiles, wait_time = NA))
  }

  tibble(
    percentile = percentiles,
    wait_time = approx(
      empirical_distribution$cdf,
      empirical_distribution$wait_time,
      xout = percentile
    )$y
  )
}

routes_for_calculation = subway_data %>%
  filter(!(route_mta_id %in% c(shuttle_routes, staten_island_routes))) %>%
  distinct(route_mta_id) %>%
  pull(route_mta_id)

wait_times_with_shuttles = map(c(routes_for_calculation, shuttle_routes), function(r) {
  wait_time_percentiles(filters = quos(
    route_mta_id == r,
    !weekend,
    hour %in% 7:19
  )) %>% mutate(route_mta_id = r)
}) %>% bind_rows()

wait_times = wait_times_with_shuttles %>%
  filter(!(route_mta_id %in% shuttle_routes))

wait_time_factor_levels = wait_times %>%
  filter(percentile == 0.5) %>%
  arrange(desc(wait_time)) %>%
  pull(route_mta_id)

png("graphs/expected_wait_times.png", width = 800, height = 1500)
wait_times %>%
  mutate(
    percentile = paste0("perc", percentile * 100),
    wait_time = wait_time / 60
  ) %>%
  spread(percentile, wait_time) %>%
  inner_join(routes, by = c("route_mta_id" = "mta_id")) %>%
  mutate(route_mta_id = factor(route_mta_id, levels = wait_time_factor_levels)) %>%
  ggplot(aes(x = route_mta_id, fill = color)) +
  geom_boxplot(aes(ymin = perc10, lower = perc25, middle = perc50, upper = perc75, ymax = perc90),
               stat = "identity") +
  scale_y_continuous("Minutes until next train arrives", minor_breaks = NULL) +
  scale_x_discrete() +
  scale_fill_identity() +
  coord_flip() +
  ggtitle("NYC Subway Wait Time Distributions", "Weekdays 7 AM–8 PM, Jan–May 2018") +
  labs(caption = paste(
    "Assumes riders arrive on platforms uniformly distributed between 7 AM and 8 PM",
    "Boxplots represent 10th, 25th, 50th, 75th, and 90th percentiles",
    "Data collected Jan–May 2018 from MTA real-time feeds",
    "toddwschneider.com",
    sep = "\n"
  )) +
  theme_tws(base_size = 36, bg_color = "#ffffff") +
  theme(
    axis.title.y = element_blank(),
    panel.grid.major.y = element_blank()
  )
dev.off()

# time between trains
time_between_trains_data = subway_data %>%
  filter(!weekend, hour %in% 7:19) %>%
  filter(route_mta_id %in% routes_for_calculation) %>%
  inner_join(routes, by = c("route_mta_id" = "mta_id"))

medians = time_between_trains_data %>%
  group_by(route_mta_id) %>%
  summarize(median = median(seconds_until_next_departure)) %>%
  ungroup() %>%
  arrange(desc(median))

png("graphs/time_between_trains.png", width = 800, height = 1500)
time_between_trains_data %>%
  mutate(route_mta_id = factor(route_mta_id, levels = medians$route_mta_id)) %>%
  ggplot(aes(x = seconds_until_next_departure / 60, y = route_mta_id, fill = color)) +
  geom_density_ridges(bandwidth = 0.5, rel_min_height = 0.01) +
  scale_fill_identity() +
  scale_x_continuous("Minutes between trains") +
  scale_y_discrete() +
  coord_cartesian(xlim = c(0, 20)) +
  ggtitle("NYC Subway Distributions of Time Between Trains", "Weekdays 7 AM–8 PM, Jan–May 2018") +
  labs(caption = "Data collected Jan–May 2018 from MTA real-time feeds\ntoddwschneider.com") +
  theme_ridges_tws(base_size = 36, center_axis_labels = TRUE) +
  theme(axis.title.y = element_blank())
dev.off()

mean_wait_times = map(routes_for_calculation, function(r) {
  d = wait_time_distribution(filters = quos(
    route_mta_id == r,
    !weekend,
    hour %in% 7:19
  ))

  tibble(route_mta_id = r, minutes = sum(d$wait_time * d$pdf) / sum(d$pdf) / 60)
}) %>% bind_rows()

# expected wait by time of day
hourly_wait_by_route = map(routes_for_calculation, function(r) {
  map(0:23, function(h) {
    df = wait_time_percentiles(filters = quos(route_mta_id == r, !weekend, hour == h)) %>%
      mutate(hour = h, route_mta_id = r)
  }) %>% bind_rows()
}) %>% bind_rows()

for (r in unique(hourly_wait_by_route$route_mta_id)) {
  filename = paste0("graphs/", r, "_train_wait_time_by_hour.png")

  route_data = hourly_wait_by_route %>%
    filter(route_mta_id == r)

  padding_data = route_data %>%
    filter(hour == 0) %>%
    mutate(hour = 24)

  route_data = bind_rows(route_data, padding_data)

  text_data = route_data %>%
    filter(!is.na(wait_time)) %>%
    filter(hour == max(hour)) %>%
    mutate(label = ifelse(percentile == 0.5, "Median", paste0(percentile * 100, "th pctile")))

  p = route_data %>%
    mutate(
      percentile = paste0("perc", percentile * 100),
      wait_time = wait_time / 60
    ) %>%
    spread(percentile, wait_time) %>%
    ggplot(aes(x = hour)) +
    geom_line(aes(y = perc50), size = 1.5, color = filter(routes, mta_id == r)$color) +
    geom_ribbon(aes(ymin = perc25, ymax = perc75), alpha = 0.3) +
    geom_ribbon(aes(ymin = perc10, ymax = perc25), alpha = 0.15) +
    geom_ribbon(aes(ymin = perc75, ymax = perc90), alpha = 0.15) +
    geom_text(
      data = text_data,
      aes(x = hour + 0.3, y = wait_time / 60, label = label),
      family = font_family, size = 5, hjust = 0
    ) +
    scale_y_continuous() +
    scale_x_continuous(breaks = c(0, 6, 12, 18, 24), labels = c("12 AM", "6 AM", "12 PM", "6 PM", "12 AM")) +
    expand_limits(y = 0, x = c(0, 26)) +
    ggtitle(paste(r, "Train Wait Time by Hour"), "Expected minutes to wait until next train, weekdays") +
    labs(caption = "Data collected Jan–May 2018 from MTA real-time feeds\ntoddwschneider.com") +
    theme_tws(base_size = 36) +
    no_axis_titles()

  png(filename, width = 800, height = 800)
  print(p)
  dev.off()
}

# conditional wait times
conditional_wait_time = function(already_waited, distribution, percentiles = c(0.1, 0.25, 0.5, 0.75, 0.9)) {
  conditional_distribution = distribution %>%
    filter(wait_time >= already_waited) %>%
    mutate(conditional_cdf = cumsum(pdf) / sum(pdf))

  tibble(
    percentile = percentiles,
    additional_wait_time = approx(
      conditional_distribution$conditional_cdf,
      conditional_distribution$wait_time - already_waited,
      xout = percentile
    )$y
  )
}

for (r in routes_for_calculation) {
  empirical_distribution = wait_time_distribution(filters =
    quos(route_mta_id == r, !weekend, hour %in% 7:19)
  )

  max_t = empirical_distribution %>%
    filter(cum_n > 1000) %>%
    pull(wait_time) %>%
    last() %>%
    min(1200)

  conditional_percentiles = map(1:max_t, function(t) {
    conditional_wait_time(t, empirical_distribution) %>%
      mutate(already_waited = t)
  }) %>%
    bind_rows() %>%
    mutate(
      already_waited = already_waited / 60,
      additional_wait_time = additional_wait_time / 60
    )

  text_data = conditional_percentiles %>%
    filter(already_waited == max(already_waited)) %>%
    mutate(label = ifelse(percentile == 0.5, "Median", paste0(percentile * 100, "th pctile")))

  p = conditional_percentiles %>%
    mutate(percentile = paste0("perc", percentile * 100)) %>%
    spread(percentile, additional_wait_time) %>%
    ggplot(aes(x = already_waited)) +
    geom_line(aes(y = perc50), size = 1.5, color = filter(routes, mta_id == r)$color) +
    geom_ribbon(aes(ymin = perc25, ymax = perc75), alpha = 0.3) +
    geom_ribbon(aes(ymin = perc10, ymax = perc25), alpha = 0.15) +
    geom_ribbon(aes(ymin = perc75, ymax = perc90), alpha = 0.15) +
    geom_text(
      data = text_data,
      aes(x = already_waited + 0.3, y = additional_wait_time, label = label),
      family = font_family, size = 5, hjust = 0
    ) +
    scale_y_continuous() +
    scale_x_continuous("Minutes since last train") +
    expand_limits(y = 0, x = c(0, 22)) +
    coord_cartesian(ylim = c(0, 20)) +
    ggtitle(paste(r, "Train Conditional Expected Wait Time"), "Additional minutes expected to wait until next train") +
    labs(caption = "Weekdays 7 AM–8 PM. Data collected Jan–May 2018 from MTA real-time feeds\ntoddwschneider.com") +
    theme_tws(base_size = 36) +
    theme(axis.title.y = element_blank())

  filename = paste0("graphs/", r, "_train_conditional_wait_time.png")

  png(filename, width = 800, height = 800)
  print(p)
  dev.off()
}

# downtown F train delays on 5/16/2018
f = subway_data %>%
  filter(route_mta_id == "F", direction == 3) %>%
  mutate(date = date(departure_time)) %>%
  filter(date == as.Date("2018-05-16")) %>%
  arrange(realtime_trip_id, departure_time)

factor_levels = filter(f, realtime_trip_id == 886334)$stop_mta_id %>% rev()
factor_labels = map(factor_levels, function(s) {
  str_split(filter(stops, mta_id == s)$name, " - ")[[1]][1]
}) %>% unlist()

f = mutate(f, stop_factor = factor(
  stop_mta_id,
  levels = factor_levels,
  labels = factor_labels
))

x_breaks = as.POSIXct("2018-05-16 07:00:00", "UTC") + (0:5) * 60 * 60

# a few trains have stops out of order, remove them for a cleaner graph
f_clean = f %>%
  filter(
    !(realtime_trip_id == 887630 & stop_mta_id %in% c("D17S", "F14S", "F15S", "F16S")),
    !(realtime_trip_id == 888224 & stop_mta_id %in% c("F06S", "F07S")),
    !(stop_mta_id == "D43S" & realtime_trip_id %in% c(886404, 886532, 887726))
  )

png("graphs/f_train_delays_20180516.png", 800, 800)
f_clean %>%
  ggplot(aes(x = departure_time, y = stop_factor, group = realtime_trip_id)) +
  geom_line(size = 1, color = "#FF6319") +
  scale_x_datetime(breaks = x_breaks, labels = c("7 AM", "8 AM", "9 AM", "10 AM", "11 AM", "12 PM")) +
  scale_y_discrete(position = "left") +
  coord_cartesian(xlim = c(as.POSIXct("2018-05-16 07:00:00", "UTC"), as.POSIXct("2018-05-16 12:00:00", "UTC"))) +
  annotate(
    "rect",
    xmin = as.POSIXct("2018-05-16 07:32:00", "UTC"),
    xmax = as.POSIXct("2018-05-16 07:55:00", "UTC"),
    ymin = 32.5,
    ymax = 34.5,
    fill = "#cc0000",
    alpha = 0.2
  ) +
  annotate(
    "rect",
    xmin = as.POSIXct("2018-05-16 09:57:00", "UTC"),
    xmax = as.POSIXct("2018-05-16 10:35:00", "UTC"),
    ymin = 26.5,
    ymax = 32.5,
    fill = "#cc0000",
    alpha = 0.2
  ) +
  ggtitle("Downtown F Trains on May 16, 2018") +
  labs(caption = "Data collected from MTA real-time feeds\ntoddwschneider.com") +
  theme_tws(base_size = 36) +
  no_axis_titles() +
  theme(
    axis.text.y = element_text(size = 12),
    panel.grid.minor.x = element_blank()
  )
dev.off()

# historical analysis
station_to_station = query("SELECT * FROM station_to_station_summary_yearly") %>%
  filter(route_mta_id %in% c(1:6, "L"))

historical_data = station_to_station %>%
  filter(trips > 100) %>%
  group_by(route_mta_id, from_stop_mta_id, to_stop_mta_id) %>%
  summarize(all_time_mean = sum(trips * mean) / sum(trips)) %>%
  ungroup() %>%
  inner_join(station_to_station) %>%
  group_by(route_mta_id, year) %>%
  summarize(ratio = sum(trips * mean / all_time_mean) / sum(trips)) %>%
  ungroup() %>%
  arrange(route_mta_id, year) %>%
  group_by(route_mta_id) %>%
  mutate(adjusted_ratio = ratio / first(ratio)) %>%
  ungroup() %>%
  inner_join(routes, by = c("route_mta_id" = "mta_id"))

png("graphs/historical_travel_times.png", width = 800, height = 800)
historical_data %>%
  ggplot(aes(x = year, y = adjusted_ratio, group = route_mta_id, color = color)) +
  geom_point(size = 3) +
  geom_line(size = 1.5) +
  geom_text(
    data = filter(historical_data, year == 2018),
    aes(
      x = year + 0.16,
      y = case_when(
        route_mta_id == "3" ~ adjusted_ratio - 0.001,
        route_mta_id == "2" ~ adjusted_ratio + 0.001,
        TRUE ~ adjusted_ratio
      ),
      label = route_mta_id
    ),
    size = 10,
    family = font_family
  ) +
  scale_color_identity() +
  scale_y_continuous(breaks = c(1, 1.025, 1.05), labels = c("1x", "1.025x", "1.05x")) +
  ggtitle("Subway Travel Times Since 2014", "Subway trip time multiplier, scaled to 2014 = 1") +
  labs(caption = "Data via MTA, 9/2014–11/2015, 1/2017–5/2018\nWeekdays 7 AM–8 PM\ntoddwschneider.com") +
  theme_tws(base_size = 36) +
  theme(panel.grid.minor.x = element_blank()) +
  no_axis_titles()
dev.off()

# directed graph
library(igraph)
# library(devtools)
# devtools::install_github("dkahle/ggmap")
library(ggmap)
# register_google(key = "your_google_maps_key")

staten_island_stops = query("
  SELECT mta_id
  FROM stops_with_geo
  WHERE borough = 'Staten Island'
    AND length(mta_id) = 3
") %>% pull(mta_id)

median_wait_times = wait_times_with_shuttles %>%
  filter(percentile == 0.5) %>%
  select(route_mta_id, wait_time)

station_to_station = query("
  SELECT *
  FROM station_to_station_summary
  WHERE from_stop_mta_id IN (SELECT mta_id FROM stops)
    AND to_stop_mta_id IN (SELECT mta_id FROM stops)
    AND (
      trips > 1000
      OR (route_mta_id = 'M' AND trips > 400)
      OR (route_mta_id IN ('FS', 'H') AND trips > 40)
        /*
        M service between between Myrtle-Wyckoff and Middle Village
        was closed until April 28, 2018; allow lower trips threshold

        Franklin Av and Rockaway shuttles (FS, H) have low trip counts
        */
    )
") %>%
  inner_join(median_wait_times, by = "route_mta_id") %>%
  mutate(
    from_stop_mta_id = substr(from_stop_mta_id, 1, 3),
    to_stop_mta_id = substr(to_stop_mta_id, 1, 3),
    weight = pct50 + wait_time
  )

all_stops_with_data = unique(c(
  station_to_station$from_stop_mta_id,
  station_to_station$to_stop_mta_id
))

transfers = query("SELECT * FROM transfers WHERE from_stop_mta_id != to_stop_mta_id") %>%
  mutate(route_mta_id = "transfer") %>%
  select(
    from = from_stop_mta_id,
    to = to_stop_mta_id,
    weight = min_transfer_time,
    route_mta_id
  ) %>%
  filter(from %in% all_stops_with_data, to %in% all_stops_with_data)

vertex_metadata = tibble(stop_mta_id = all_stops_with_data) %>%
  left_join(stops, by = c("stop_mta_id" = "mta_id")) %>%
  select(name = stop_mta_id, description = name, borough)

subway_graph = station_to_station %>%
  select(
    from = from_stop_mta_id,
    to = to_stop_mta_id,
    weight,
    route_mta_id
  ) %>%
  bind_rows(transfers) %>%
  graph_from_data_frame(directed = TRUE, vertices = vertex_metadata)

station_paths = function(from_stop_mta_id, to_stop_mta_ids = V(subway_graph)) {
  paths = shortest_paths(
    subway_graph,
    from = from_stop_mta_id,
    to = to_stop_mta_ids,
    output = "both"
  )

  map(1:length(paths$vpath), function(i) {
    v = paths$vpath[[i]]
    e = paths$epath[[i]]

    routes_count = unique(e$route_mta_id) %>% setdiff("transfer") %>% length()

    tibble(
      from_stop_mta_id = from_stop_mta_id,
      to_stop_mta_id = rev(v$name)[1],
      minutes = sum(e$weight) / 60,
      routes_count = routes_count,
      boroughs_count = length(unique(v$borough)),
      start_borough = v$borough[1],
      end_borough = rev(v$borough)[1],
      routes = paste(e$route_mta_id, collapse = " -> "),
      stops = paste(v$name, collapse = " -> "),
      desc = paste(v$description, collapse = " -> "),
      weight = sum(e$weight),
      starts_with_transfer = e$route_mta_id[1] == "transfer",
      ends_with_transfer = rev(e$route_mta_id)[1] == "transfer"
    )
  }) %>% bind_rows()
}

# calculate shortest path from every stop to every other stop
all_paths = map(all_stops_with_data, function(s) {
  station_paths(s, all_stops_with_data)
}) %>% bind_rows()

# some setup to allow plotting individual subway routes on a map
track_coordinates = query("
  SELECT
    rs.route_mta_id,
    p.sequence,
    p.latitude,
    p.longitude
  FROM routes_shapes rs
    INNER JOIN shapes p ON rs.shape_mta_id = p.mta_id
  ORDER BY rs.route_mta_id, p.sequence
") %>%
  mutate(
    lat4 = round(latitude, 4),
    lon4 = round(longitude, 4)
  )

stops_for_join = stops %>%
  filter(nchar(mta_id) == 3) %>%
  mutate(
    lat4 = round(latitude, 4),
    lon4 = round(longitude, 4)
  )

route_coords_single_leg = function(from_stop_mta_id, to_stop_mta_id, route_mta_id) {
  if (route_mta_id == "transfer") {
    df = stops %>%
      filter(mta_id %in% c(from_stop_mta_id, to_stop_mta_id)) %>%
      mutate(
        from_stop_mta_id = from_stop_mta_id,
        to_stop_mta_id = to_stop_mta_id,
        route_mta_id = "transfer",
        leg = paste(from_stop_mta_id, to_stop_mta_id, sep = "_"),
        color = "#222222"
      ) %>%
      select(from_stop_mta_id, to_stop_mta_id, route_mta_id, leg, color, longitude, latitude)

    return(df)
  }

  route_stops = stops_for_join %>%
    filter(mta_id %in% c(from_stop_mta_id, to_stop_mta_id))

  full_route_coordinates = track_coordinates %>%
    filter(route_mta_id == UQ(route_mta_id))

  joined_stops = route_stops %>%
    inner_join(full_route_coordinates, by = c("lat4", "lon4"))

  missing_stops = c(from_stop_mta_id, to_stop_mta_id) %>%
    setdiff(unique(joined_stops$mta_id))

  if (length(missing_stops) > 0) {
    stop(paste0("Couldn't find coordinates for ", paste(missing_stops, collapse = ", ")))
  }

  full_route_coordinates %>%
    filter(
      sequence >= min(joined_stops$sequence),
      sequence <= max(joined_stops$sequence)
    ) %>%
    mutate(
      from_stop_mta_id = from_stop_mta_id,
      to_stop_mta_id = to_stop_mta_id,
      leg = paste(from_stop_mta_id, to_stop_mta_id, sep = "_"),
      color = filter(routes, mta_id == UQ(route_mta_id))$color
    ) %>%
    select(from_stop_mta_id, to_stop_mta_id, route_mta_id, leg, color, longitude, latitude)
}

route_coords = function(from_stop_mta_id, to_stop_mta_id) {
  full_path = shortest_paths(
    subway_graph,
    from = from_stop_mta_id,
    to = to_stop_mta_id,
    output = "both"
  )

  vertices = full_path$vpath[[1]]$name

  pairs = tibble(
    from = vertices[-length(vertices)],
    to = vertices[-1],
    route = full_path$epath[[1]]$route_mta_id
  )

  map(1:nrow(pairs), function(i) {
    pair = pairs[i, ]
    route_coords_single_leg(pair$from, pair$to, pair$route)
  }) %>% bind_rows()
}

plot_route = function(from_stop_mta_id, to_stop_mta_id, zoom = 13,
                      base_map = NULL, add_markers = TRUE) {
  legs = route_coords(from_stop_mta_id, to_stop_mta_id)

  if (add_markers) {
    markers = stops %>%
      filter(mta_id %in% c(from_stop_mta_id, to_stop_mta_id)) %>%
      select(longitude, latitude)
  } else {
    markers = ""
  }

  if (is.null(base_map)) {
    base_map = get_googlemap(
      center = c(lon = mean(range(legs$longitude)), lat = mean(range(legs$latitude))),
      zoom = zoom,
      style = "feature:poi|visibility:off",
      markers = markers
    )
  }

  ggmap(base_map, extent = "device") +
    geom_path(
      data = legs,
      aes(x = longitude, y = latitude, group = leg, color = color),
      size = 1.5, lineend = "round"
    ) +
    scale_color_identity()
}

png("graphs/wakefield_to_far_rockaway.png", width = 640, height = 640)
plot_route("201", "H15", zoom = 11, add_markers = FALSE)
dev.off()

plot_route_multi = function(legs, markers = NULL, zoom = 13, base_map = NULL, style = "feature:poi|visibility:off") {
  if (is.null(base_map)) {
    base_map = get_googlemap(
      center = c(lon = mean(range(legs$longitude)), lat = mean(range(legs$latitude))),
      zoom = zoom,
      style = style
    )
  }

  p = ggmap(base_map, extent = "device") +
    geom_path(
      data = legs,
      aes(x = longitude, y = latitude, group = leg, color = color),
      size = 1.5, lineend = "round"
    ) +
    scale_color_identity()

  if (!is.null(markers)) {
    p = p + geom_point(
      data = markers,
      aes(x = longitude, y = latitude),
      size = 4
    )
  }

  p
}

# find the station that has the closest farthest-away station
all_paths %>%
  filter(from_stop_mta_id != to_stop_mta_id) %>%
  filter(!ends_with_transfer) %>%
  group_by(from_stop_mta_id) %>%
  top_n(1, minutes) %>%
  ungroup() %>%
  arrange(minutes)

borough_routes = all_paths %>%
  filter(from_stop_mta_id == "228", !ends_with_transfer) %>%
  group_by(end_borough) %>%
  top_n(1, minutes) %>%
  ungroup()

legs = map(1:nrow(borough_routes), function(i) {
  route = borough_routes[i, ]
  route_coords(route$from_stop_mta_id, route$to_stop_mta_id)
}) %>% bind_rows()

marker = stops %>%
  filter(mta_id == "228") %>%
  select(longitude, latitude)

p = plot_route_multi(legs, marker, zoom = 11, style = "element:labels|visibility:off")

png("graphs/chambers_st.png", width = 640, height = 640)
p + annotate(
  "label",
  x = marker$longitude - 0.055,
  y = marker$latitude,
  label = "Chambers St",
  family = font_family,
  size = 7
)
dev.off()

desired_zones = c("Upper West Side North", "Bushwick South", "Park Slope")
filter(stops, zone %in% desired_zones, nchar(mta_id) == 3)

# find the station that has the closest farthest-away station in Upper West Side/Bushwick/Park Slope
desired_stops = c("120", "L14", "F24")

all_paths %>%
  filter(from_stop_mta_id != to_stop_mta_id) %>%
  filter(!ends_with_transfer) %>%
  filter(to_stop_mta_id %in% desired_stops) %>%
  group_by(from_stop_mta_id) %>%
  top_n(1, minutes) %>%
  ungroup() %>%
  arrange(minutes)

worst_case_routes = all_paths %>%
  filter(from_stop_mta_id == "D20", to_stop_mta_id %in% desired_stops) %>%
  inner_join(stops, by = c("to_stop_mta_id" = "mta_id")) %>%
  group_by(zone) %>%
  top_n(1, minutes) %>%
  ungroup()

legs = map(1:nrow(worst_case_routes), function(i) {
  route_coords(
    worst_case_routes$from_stop_mta_id[i],
    worst_case_routes$to_stop_mta_id[i]
  )
}) %>% bind_rows()

marker = stops %>%
  filter(mta_id == "D20") %>%
  select(longitude, latitude)

p = plot_route_multi(legs, marker, zoom = 12, style = "feature:poi|visibility:off")

png("graphs/w4_st.png", width = 640, height = 640)
p + annotate(
  "label",
  x = marker$longitude - 0.02,
  y = marker$latitude,
  label = "W 4th St",
  family = font_family,
  size = 7
)
dev.off()

# fastest path through all 4 boroughs
all_paths %>%
  filter(boroughs_count == 4) %>%
  arrange(minutes)

png("graphs/four_boroughs.png", width = 640, height = 640)
plot_route("416", "G26", zoom = 12)
dev.off()

# center of each borough
all_paths %>%
  filter(from_stop_mta_id != to_stop_mta_id) %>%
  filter(!ends_with_transfer) %>%
  filter(start_borough == end_borough) %>%
  group_by(start_borough, from_stop_mta_id) %>%
  top_n(1, minutes) %>%
  ungroup() %>%
  group_by(start_borough) %>%
  top_n(-1, minutes) %>%
  arrange(minutes)
