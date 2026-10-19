## -- SPAM Data  -- ##

# Pull in latest data pull 
df <-read.csv('app/data/full_pull.csv')

# Add in more time elements, change to lowercase
df <- df |>  
  dplyr::mutate(date = lubridate::dmy(LAND_DATE),
                year = lubridate::year(date),
                month = as.character(lubridate::month(date,
                                                      label = TRUE, 
                                                      abbr = FALSE)), 
                week = lubridate::week(date), 
                day = lubridate::day(date)) |> 
  dplyr::rename_with(tolower)

# Prepping to add to stat area centroid locations 
df$stat.lat <- NA
df$stat.lon <- NA

## -- Setting up spatial information -- ##

# Pull in GARFO stat areas
stat.areas <- readRDS('app/data/spam_stat_areas.rds')
# Isolate unique stat areas based on SPAM data
unq.stat.areas <- sort(unique(df$area_code))
unq.stat.areas <- unq.stat.areas[-1] # remove stat area 0
unq.stat.areas
spam.stat.areas <- stat.areas[na.omit(stat.areas$Id %in% unq.stat.areas),]
# Calc centroid of each stat area
stat.ctrds <- sf::st_point_on_surface(spam.stat.areas)
# Create a dataframe of stat area geometries to add to SPAM dataframe
stat.areas.df <- stat.ctrds |> 
  dplyr::bind_cols(sf::st_coordinates(stat.ctrds)) |> 
  dplyr::rename(lon = X, lat = Y) |> 
  sf::st_drop_geometry() |> 
  as.data.frame()

# Add the centroid coordinates based on location for SPAM samples 
for (i in 1:length(unq.stat.areas)){
  tmp <- subset(df, area_code == unq.stat.areas[i])
  locs <- which(df$area_code %in% tmp$area_code)
  b <- subset(stat.areas.df, Id == unq.stat.areas[i], select = 'lat')
  c <- subset(stat.areas.df, Id == unq.stat.areas[i], select = 'lon')
  df[locs,'stat.lat'] <- b$lat
  df[locs,'stat.lon'] <- c$lon
}

# Pivot the dataset from long to wide so param_type is not duplicated
# also add GSI calculations, characters for sex instead of numbers & regions
df.wide <- df  |>  
  dplyr::select(tally_no, vessel_name, land_date, area_code,
                stat.lat, stat.lon, latitude, longitude, 
                organism_id, date, year, month, week, day, 
                param_value_num, param_type) |> 
  tidyr::pivot_wider(names_from = "param_type", values_from = "param_value_num") |>  
  dplyr::mutate(GSI = (GW/OW)*100, 
                sex = dplyr::case_when(
                  SEX == 1 ~ 'M', 
                  SEX == 2 ~ 'F', 
                  SEX == 0 ~ 'U', 
                  TRUE ~ NA), 
                region = dplyr::case_when(
                  area_code %in% c(511, 512, 513, 514, 515, 521, 522, 525,
                                   561, 562) ~ "North",
                  area_code %in% c(533, 537, 526, 538, 539, 611, 612,
                                   613, 614, 615,
                                   616, 621, 622, 623, 625, 626, 627, 631, 
                                   632, 635, 636) ~ "South",
                  TRUE ~ NA_character_))
# Run once during data pipeline generation:
saveRDS(df.wide, "app/data/df_wide_preprocessed.rds")
saveRDS(spam.stat.areas, "app/data/spam_stat_areas_filtered.rds")
#write.csv(df.wide, "app/data/spam_full_data_09302026.csv",row.names = FALSE)
