# Based on "Extraction of a large time series of meteorological variables"
# https://epi-rgee.netlify.app/demos/02_time_series/

library(reticulate)
use_virtualenv("rgee")
library(rgee)

library(sf)
library(tidyverse)

ee_Initialize()


# Load ERA5-Land ----------------------------------------------------------

# ERA5-Land is better than ERA5 because it is a "reanalysis" dataset
#
# https://epi-rgee.netlify.app/post/03_rgee-rspatial/
# https://developers.google.com/earth-engine/datasets/catalog/ECMWF_ERA5_LAND_MONTHLY_AGGR

era5land <- ee$ImageCollection$Dataset$ECMWF_ERA5_LAND_MONTHLY$
  select(c("dewpoint_temperature_2m", "temperature_2m"))$
  filterDate("1990-01-01","2021-12-31")$
  toBands()


# Import areas ------------------------------------------------------------

lima <- read_sf(
  "https://github.com/healthinnovation/sdb-gpkg/raw/main/Lima_provincia.gpkg",
  quiet = TRUE
  ) |>
  summarise()

peru_dep <- read_sf(
  "https://github.com/healthinnovation/sdb-gpkg/raw/main/departamentos.gpkg",
  quiet = TRUE
  ) |>
  select(NOMBDEP) |>
  set_names(tolower)


# Statistics for Lima -----------------------------------------------------

lima_ee <-  lima |>
  sf_as_ee()

# start: 21:27
# end: 21:29
lima_extraction <- ee_extract(
  x = era5land,
  y = lima_ee,
  fun = ee$Reducer$mean(),
  sf = FALSE
  )

lima_temperature <- lima_extraction |>
  pivot_longer(
    everything(),
    # use .value instead of "variable" to create two columns
    names_to = c("year", "month", "variable"),
    names_pattern = "X(\\d{4})(\\d{2})_(.*)"
    ) |>
  mutate(
    date = make_date(year, month),
    value = value - 273.15
    ) |>
  relocate(date, .before = everything())

# strong seasonality
lima_temperature |>
  ggplot(aes(date, value, colour = variable)) +
  geom_line() +
  theme(legend.position = "top") +
  labs(
    x = NULL, colour = NULL,
    y = "Temperature (C°)"
  )
ggsave("rgee-example-lima-abs.png")

lima_temperature |>
  group_by(variable, month) |>
  mutate(value = value - mean(value)) |>
  ungroup() |>
  ggplot(aes(date, value, colour = variable)) +
  geom_hline(yintercept = 0, linewidth = 2, colour = "white") +
  geom_line() +
  theme(legend.position = "top") +
  labs(
    x = NULL, colour = NULL,
    y = "Deviation from historic monthly average (C°)"
  )
ggsave("rgee-example-lima-rel.png")


# Statistics for Peruvian regions -----------------------------------------

# TODO: There should be a better way of doing this, without exporting the
# regional geometries one by one. However, will probably need to use native EE
# syntax. A good place to start could be the internals of ee_extract()

ee_extract_era5land <- function(area) {
  area_ee <- sf_as_ee(area)
  # this assignment is a must! rgee is lazy
  extraction <- ee_extract(
    x = era5land,
    y = area_ee,
    fun = ee$Reducer$mean(),
    sf = FALSE
  )
  extraction
}

# previous run with 24 regions took aprox. ~32 min
peru_dep_extract <- split(peru_dep, peru_dep$nombdep) |>
  head(2) |>
  purrr::map(ee_extract_era5land)

peru_temperature <- peru_dep_extract |>
  bind_rows(.id = "nombdep") |>
  pivot_longer(
    -nombdep,
    # use .value instead of "variable" to create two columns
    names_to = c("year", "month", ".value"),
    names_pattern = "X(\\d{4})(\\d{2})_(.*)"
  ) |>
  mutate(
    date = make_date(year, month),
    across(contains("temperature"), \(x) x - 273.15)
  ) |>
  relocate(date, .before = everything())

peru_temperature |>
  ggplot(aes(date, temperature_2m, colour = nombdep)) +
  geom_line() +
  labs(
    x = NULL,
    y = "Temperature (C°)",
    colour = "Region"
  )
ggsave("rgee-example-peru-abs.png")

# Other links (unexplored):
#
# https://www.css.cornell.edu/faculty/dgr2/_static/files/R_html/ex_rgee.html#52_Climate_analysis
# https://csaybar.github.io/rgee-examples/
# https://stackoverflow.com/questions/67974730/extract-values-of-multiple-lat-lon-for-image-collection-in-earth-engine-using-rg
# https://confluence.ecmwf.int/display/FCST/Gaussian+grids
