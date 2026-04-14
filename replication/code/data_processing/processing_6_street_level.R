################################################################################
# Project: Philadelphia Lighting
#	File: processing_6_street_level.R
#	Script purpose: create light-crime-street mapping
#	Author: Maya Moritz
#	Input: data_folder_raw/streets
#	Output: data_folder_temp/streets with 4 files:
#         joined_segments.csv
#         lights_streets.csv
#         crime_streets.csv
#         shooting_streets.csv
################################################################################

#Set your working directory here:
setwd("C:/Users/mayar/Documents/GitHub/Lighting_Replication/data")

#Load libraries
#install.packages("sf")  # Install the 'sf' package if you haven't already
#install.packages("sp")  # Install the 'sp' package for spatial operations
library(sf)
library(sp)
library(readxl)
library(readr)
library(arsenal)

################################################################################
######################### LINK LIGHTS AND CRIMES TO STREETS ####################
################################################################################

#read lights and crime data
lights <- read_excel("raw/PSIP Fixture Export May 6 2024.xlsx")

crime <- read_csv("raw/crime/incidents_part1_part2.csv")
shootings<-read_csv("raw/crime/shootings.csv")

#now read in shape file from Open Philadelphia
mapstreets <- st_read("raw/mapping/streets/Street_Centerline.shp")

lights$Y<-as.numeric(lights$Lat)
lights$X<-as.numeric(lights$Lon)
# Filter out rows with missing x-y coordinates
lights <- lights[complete.cases(lights[c("X", "Y")]), ]
crime <- crime[complete.cases(crime[c("point_x", "point_y")]), ]
shootings <- shootings[complete.cases(shootings[c("point_x", "point_y")]), ]
# Convert the point data to a spatial object
lights_points <- st_as_sf(lights, coords = c("X", "Y"), crs = st_crs(mapstreets))
crime_points <- st_as_sf(crime, coords = c("point_x", "point_y"), crs = st_crs(mapstreets))
shooting_points <- st_as_sf(shootings, coords = c("point_x", "point_y"), crs = st_crs(mapstreets))
# Perform the spatial join to street segments
lights_streets <- st_join(lights_points, mapstreets, join = st_nearest_feature)
crime_streets <- st_join(crime_points, mapstreets, join = st_nearest_feature)
shooting_streets <- st_join(shooting_points, mapstreets, join = st_nearest_feature)

#drop geometry now they are linked
lights_streets <- st_drop_geometry(lights_streets)
crime_streets <- st_drop_geometry(crime_streets)
shooting_streets <- st_drop_geometry(shooting_streets)

write.csv(lights_streets, "temp/streets/lights_streets.csv", row.names = TRUE)
write.csv(crime_streets, "temp/streets/crime_streets.csv", row.names = TRUE)
write.csv(shooting_streets, "temp/streets/shooting_streets.csv", row.names = TRUE)



################################################################################
######################## IDENTIFY ADJACENT STREET SEGMENTS #####################
################################################################################

#Read the shapefile
street_centerlines <- st_read("raw/mapping/streets/Street_Centerline.shp")

# Reproject to a CRS with feet (e.g., NAD83 / StatePlane PA South Feet, EPSG: 2227)
# You may need to choose the CRS that is appropriate for your area of interest
street_centerlines <- st_transform(street_centerlines, crs = 2272) 

# Perform spatial join with distance in feet
distance_feet <- 10 # Distance in feet

joined_segments <- st_join(
  x = street_centerlines, 
  y = street_centerlines, 
  join = st_is_within_distance, 
  dist = distance_feet
)

# Convert joined_segments to a data frame, excluding geometry
joined_segments_df <- as.data.frame(st_drop_geometry(joined_segments))

# Export the data frame to a CSV file
write.csv(joined_segments_df, "temp/streets/joined_segments.csv", row.names = FALSE)


