source("nightlight.R")

# set the root folder for where you want to download the dataset
NOAA_DATASET_ROOT <- "~/Projects/koala/datasets/noaa"

# You need to do this only once
nightlight_download(NOAA_DATASET_ROOT)

nightlight_data <- nightlight_load(NOAA_DATASET_ROOT)

# create a polygon for testing
coordinates <- matrix(
  c(
    113.4789, 22.19556,
    113.4811, 22.21748,
    113.4941, 22.24155,
    113.5271, 22.24595,
    113.5481, 22.22261,
    113.5455, 22.22148,
    113.4988, 22.20166,
    113.4842, 22.19775,
    113.4789, 22.19556
  ),
  ncol = 2,
  byrow = TRUE
)

polygon = Polygon(coordinates)
spatial_polygons = SpatialPolygons(list(Polygons(list(polygon),1)))

# apply a function to the polygon data for each year
nightlight_apply(nightlight_data, c(spatial_polygons), mean)
