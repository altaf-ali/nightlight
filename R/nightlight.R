library(RCurl)
library(R.utils)
library(raster)
library(stringr)
library(dplyr)

#' Download nighlight data from NOAA
#'
#' \code{nightlight_download} downloads nightlight data from NOAA's website and places it the specified destination directory
#'
#' @param dest destination folder for the downloaded nightight data
#' @param src source URL of NOAA nightlight data
#' @param max_retry maximum number of retries
#' @examples
#' library(nightlight)
#'
#' nightlight_download("~/datasets/noaa")
#' @importFrom magrittr "%>%"
#' @export
nightlight_download <- function(dest = ".", src = "ftp://ftp.ngdc.noaa.gov/STP/DMSP/web_data/v4composites", max_retry = 5) {
  message("Downloading nightlight data from ", src)
  files <- RCurl::getURL(src, verbose = FALSE, dirlistonly = TRUE)
  files <- strsplit(files, "\n")[[1]]

  i <- 0
  message("  ", length(files), " total files")
  for (f in files) {
    i <- i + 1
    tar_file <- file.path(tempdir(), f)

    retry <- 0
    while(retry < max_retry) {
      retry <- retry + 1
      if (length(Sys.glob(file.path(dest, (paste0(stringr::str_extract(f, "^F\\d{6}.v4"), "?_web.stable_lights.avg_vis.tif")))))) {
        message(sprintf("  %2d/%d: %s skipping", i, length(files), f))
        break
      }

      message(sprintf("  %2d/%d: %s -> %s (retry %d/%d)", i, length(files), f, tar_file, retry, max_retry))
      file.remove(tar_file)
      tryCatch(utils::download.file(file.path(src, f), destfile = tar_file, quiet = TRUE),
         warning = function(w) { file.remove(tar_file) },
         error = function(e) { file.remove(tar_file) }
      )
      if (file.exists(tar_file)) {
        break
      }
    }

    if (file.exists(tar_file)) {
      tif.gz_file <- grep("^F\\d{6}\\.v4._web\\.stable_lights.avg_vis\\.tif\\.gz$", untar(tar_file, list = TRUE), value = TRUE)
      utils::untar(tar_file, files = tif.gz_file, exdir = path.expand(dest))
      tif.gz_file <- file.path(dest, tif.gz_file)
      tif_file <- tools::file_path_sans_ext(tif.gz_file)
      if (file.exists(tif_file))
        file.remove(tif_file)
      R.utils::gunzip(tif.gz_file)
      file.remove(tar_file)
      basename(tif_file)
    }
  }
}

#' Load the nightlight dataset and return a vector of raster objects
#'
#' \code{nightlight_load} loads nightlight data from the specified destination directory and returns a vector of raster objects
#'
#' @param src source folder where nightlight data was downloaded
#' @param logfun a logging function
#' @examples
#' library(nightlight)
#'
#' nightlight_load("~/datasets/noaa")
#' @importFrom magrittr "%>%"
#' @export
nightlight_load <- function(src, logfun = message) {
  files <- data.frame(
    year = NA,
    satellite = NA,
    name = grep("^F\\d{6}\\.v4._web\\.stable_lights.avg_vis\\.tif$", list.files(src), value = TRUE))

  files <- files %>%
    dplyr::mutate(basename = stringr::str_extract(name, "^F\\d{6}.v4"),
           satellite = substr(basename, 2, 3),
           year = substr(basename, 4, 7)) %>%
    dplyr::arrange(year) %>%
    dplyr::group_by(year) %>%
    dplyr::filter(rank(satellite) == max(rank(satellite)))

  sapply(files$name, function(filename) {
    logfun(paste("loading", filename))
    raster::raster(file.path(src, filename))
  })
}

#' Apply a function to each geometric object
#'
#' \code{nightlight_apply} applies a function over each geometric object in \code{geom} for each year of nightlight data in \code{nightlight_data}
#'
#' @param nightlight_data source path where nightlight data was downloaded
#' @param geom geometric object
#' @param func function to apply
#' @param ... arguments passed to \code{func}
#' @examples
#' library(nightlight)
#'
#' set the root folder for where you want to download the dataset
#' NOAA_DATASET_ROOT <- "~/datasets/noaa"
#'
#' nightlight_download(NOAA_DATASET_ROOT)
#'
#' nightlight_data <- nightlight_load(NOAA_DATASET_ROOT)
#'
#' create a polygon for testing
#' coordinates <- matrix(
#'   c(
#'     113.4789, 22.19556,
#'     113.4811, 22.21748,
#'     113.4941, 22.24155,
#'     113.5271, 22.24595,
#'     113.5481, 22.22261,
#'     113.5455, 22.22148,
#'     113.4988, 22.20166,
#'     113.4842, 22.19775,
#'     113.4789, 22.19556
#'   ),
#'   ncol = 2,
#'   byrow = TRUE
#' )
#' polygon <- Polygon(coordinates)
#'
#' spatial_polygons <- SpatialPolygons(list(Polygons(list(polygon),1)))
#'
#' results <- nightlight_apply(nightlight_data, c(spatial_polygons), mean, na.rm = TRUE)
#'
#' print(results)
#' @importFrom magrittr "%>%"
#' @export

nightlight_apply <- function(nightlight_data, geom, func, ...) {
  results <- data.frame(matrix(NA, nrow = length(geom), ncol = length(nightlight_data)))
  cols <- sapply(nightlight_data, function(n) { strsplit(n@data@names, "\\.")[[1]][[1]] })
  results <- setNames(results, cols)

  for (i in seq_along(geom)) {
    extent_obj <- raster::extent(geom[[i]])
    for (j in seq_along(nightlight_data)) {
      cropped_obj <- raster::crop(nightlight_data[[j]], extent_obj)
      masked_obj <- raster::mask(cropped_obj, geom[[i]])
      results[i, j] <- func(values(masked_obj), ...)
    }
  }

  return(results)
}
