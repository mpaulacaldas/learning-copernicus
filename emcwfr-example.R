library(tidyverse)
library(ecmwfr)
library(sf)
library(terra)

# Python code to aggregate before fetching
code <-"
import cdstoolbox as ct

@ct.application()
@ct.output.download()
def get_daily_max(year):

    # Retrieve the hourly 2m temperature over Lima for 20230101
    temperature = ct.catalogue.retrieve(
        'reanalysis-era5-single-levels',
        {
            'variable': '2m_temperature',
            'product_type': 'reanalysis',
            'year': year,
            'month': ['01'],
            'day': list(range(1, 31 + 1)),
            'time': [
                '00:00', '01:00', '02:00', '03:00', '04:00', '05:00',
                '06:00', '07:00', '08:00', '09:00', '10:00', '11:00',
                '12:00', '13:00', '14:00', '15:00', '16:00', '17:00',
                '18:00', '19:00', '20:00', '21:00', '22:00', '23:00'
            ],
            'grid': [0.25, 0.25],
            'area': [-11., -78., -13., -76.], # only for Lima bbox
        }
    )

    # Compute the daily mean temperature over Europe
    temperature_daily_max = ct.cube.resample(temperature, freq='day', how='min')

    return temperature_daily_max
"

# The workflow name must correspond to the Python function name
request <- list(
  code = code,
  kwargs = list(year = 2023),
  workflow_name = "get_daily_max",
  target = "daily_max_lima.nc"
)

# Gets downloaded to a temporary folder
target_path <- wf_request(request, user = "XXXX")
#> [1] "/var/folders/2_/gp4d_wq5369dm9hvtjpr5vvm0000gn/T//RtmpCiHX0y/daily_max_lima.nc"


# Check result ------------------------------------------------------------

(r <- terra::rast(target_path))
#> class       : SpatRaster
#> dimensions  : 9, 9, 31  (nrow, ncol, nlyr)
#> resolution  : 0.25, 0.25  (x, y)
#> extent      : -78.125, -75.875, -13.125, -10.875  (xmin, xmax, ymin, ymax)
#> coord. ref. : lon/lat WGS 84
#> source      : daily_max_lima.nc:t2m
#> varname     : t2m (2 metre temperature)
#> names       : t2m_1, t2m_2, t2m_3, t2m_4, t2m_5, t2m_6, ...
#> unit        :     K,     K,     K,     K,     K,     K, ...
#> time (days) : 2023-01-01 to 2023-01-31

lima <- read_sf(
  "https://github.com/healthinnovation/sdb-gpkg/raw/main/Lima_provincia.gpkg",
  quiet = TRUE
  ) |> dplyr::summarise()

# raster for day 01, where each pixel gives the maximum temperature in the day
# the area for lima is pretty small given the resolution
plot(r$t2m_1)
plot(lima, add = TRUE)

# get the maximum temperature reached in the area
terra::extract(r, lima, fun = "max", ID = FALSE) |>
  pivot_longer(everything()) |>
  separate(name, c("variable", "day"), sep = "_", convert = TRUE) |>
  mutate(value = value - 273.15) |>
  ggplot(aes(day, value)) +
  geom_line()
