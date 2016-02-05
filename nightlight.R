library(RCurl)
library(R.utils)
library(raster)
library(stringr)
library(dplyr)

# It takes a while to download all the data
nightlight_download <- function(dest = NULL, src = "ftp://ftp.ngdc.noaa.gov/STP/DMSP/web_data/v4composites/") {
  message("Downloading nightlight data from ", src)
  files <- getURL(src, verbose = FALSE, dirlistonly = TRUE) 
  files <- strsplit(files, "\n")[[1]]
  
  sapply(files, function(f) {
    tar_file <- file.path(tempdir(), f)
    message("  ", f, " -> ", tar_file)  
    download.file(file.path(src, f), destfile = tar_file, quiet = TRUE)
    tif.gz_file <- grep("^F\\d{6}\\.v4._web\\.stable_lights.avg_vis\\.tif\\.gz$", untar(tar_file, list = TRUE), value = TRUE)
    untar(tar_file, files = tif.gz_file, exdir = path.expand(dest))
    tif.gz_file <- file.path(dest, tif.gz_file)
    tif_file <- tools::file_path_sans_ext(tif.gz_file)
    if (file.exists(tif_file))
      file.remove(tif_file)
    gunzip(tif.gz_file)
    file.remove(tar_file)
    basename(tif_file)
  })
}

# load the nightlight dataset and return a list of raster objects
nightlight_load <- function(nightlight_root) {
  files <- data.frame(
    year = NA,
    satellite = NA,
    name = grep("^F\\d{6}\\.v4._web\\.stable_lights.avg_vis\\.tif$", list.files(nightlight_root), value = TRUE))
  
  files <- files %>%
    mutate(basename = str_extract(name, "^F\\d{6}.v4"),
           satellite = substr(basename, 2, 3),
           year = substr(basename, 4, 7)) %>%
    arrange(year) %>%
    group_by(year) %>%
    filter(rank(satellite) == max(rank(satellite)))
  
  sapply(files$name, function(filename) {
    message("loading ", filename)
    raster(file.path(nightlight_root, filename))
  })
}

# apply a function to each geometric object
nightlight_apply <- function(nightlight_data, geom, func, ...) {
  results <- data.frame(matrix(NA, nrow = length(geom), ncol = length(nightlight_data)))
  cols <- sapply(nightlight_data, function(n) { strsplit(n@data@names, "\\.")[[1]][[1]] })
  results <- setNames(results, cols)

  for (i in seq_along(geom)) {
    extent_obj <- extent(geom[[i]])
    for (j in seq_along(nightlight_data)) {
      cropped_obj <- crop(nightlight_data[[j]], extent_obj)
      masked_obj <- mask(cropped_obj, geom[[i]])
      results[i, j] <- func(values(masked_obj), ...)
    }
  }
  
  results
}

