library(sf)
library(tidyverse)
library(reticulate)

use_virtualenv("cds")

cdsapi <- import('cdsapi')


# Define boundaries -------------------------------------------------------

lima <- read_sf(
  "https://github.com/healthinnovation/sdb-gpkg/raw/main/Lima_provincia.gpkg",
  quiet = TRUE
  ) |>
  summarise()

bb <- as.list(st_bbox(lima))

b <- list(
  north = ceiling(bb$ymax),
  south = floor(bb$ymin),
  east  = ceiling(bb$xmax),
  west  = floor(bb$xmin)
)

area_spec <- str_c(b$north, b$west, b$south, b$east, sep = "/")
#> [1] "-11/-78/-13/-76"

# Download ----------------------------------------------------------------

# Start the connection
server <- cdsapi$Client()

query_params <- list(
  variable     = "2m_temperature",
  product_type = "reanalysis",
  year   = "2023",
  month  = "01",
  day    = "01",
  time   = 0:23 |> str_c("00", sep = ":") |> str_pad(5, "left", "0"),
  format = "netcdf",
  area   = area_spec
)

# Transfer the list to Python
query <- r_to_py(query_params)

# Fetch the ncdf
server$retrieve("reanalysis-era5-single-levels", query, "era5_ta_20230101.nc")


# Benchmark info ----------------------------------------------------------

units::set_units(st_area(lima), km^2)
#> 2851.448 [km^2]

# 1 day
fs::file_size("era5_ta_20230101.nc")
#> 5.01K

# all historical
fs::file_size("era5_ta_20230101.nc") * 365 * (2023 - 1940 + 1)
#> 150M


# Read --------------------------------------------------------------------

r <- terra::rast("era5_ta_20230101.nc")
#> class       : SpatRaster
#> dimensions  : 9, 9, 24  (nrow, ncol, nlyr)
#> resolution  : 0.25, 0.25  (x, y)
#> extent      : -78.125, -75.875, -13.125, -10.875  (xmin, xmax, ymin, ymax)
#> coord. ref. : lon/lat WGS 84
#> source      : era5_ta_20230101.nc
#> varname     : t2m (2 metre temperature)
#> names       : t2m_1, t2m_2, t2m_3, t2m_4, t2m_5, t2m_6, ...
#> unit        :     K,     K,     K,     K,     K,     K, ...
#> time        : 2023-01-01 to 2023-01-01 23:00:00 UTC

rr <- raster::raster("era5_ta_20230101.nc")
#> class      : RasterLayer
#> band       : 1  (of  24  bands)
#> dimensions : 9, 9, 81  (nrow, ncol, ncell)
#> resolution : 0.25, 0.25  (x, y)
#> extent     : -78.125, -75.875, -13.125, -10.875  (xmin, xmax, ymin, ymax)
#> crs        : +proj=longlat +datum=WGS84 +no_defs
#> source     : era5_ta_20230101.nc
#> names      : X2.metre.temperature
#> z-value    : 2023-01-01
#> zvar       : t2m
