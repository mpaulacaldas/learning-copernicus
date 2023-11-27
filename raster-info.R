rast   <- terra::rast("data.nc")
#> class       : SpatRaster
#> dimensions  : 1801, 3600, 24  (nrow, ncol, nlyr)
#> resolution  : 0.1, 0.1  (x, y)
#> extent      : -0.05, 359.95, -90.05, 90.05  (xmin, xmax, ymin, ymax)
#> coord. ref. :
#>   source      : data.nc
#> varname     : t2m (2 metre temperature)
#> names       : t2m_1, t2m_2, t2m_3, t2m_4, t2m_5, t2m_6, ...
#> unit        :     K,     K,     K,     K,     K,     K, ...
#> time        : 2023-01-01 to 2023-01-01 23:00:00 UTC

raster <- raster::raster("data.nc")
#> class      : RasterLayer
#> band       : 1  (of  24  bands)
#> dimensions : 1801, 3600, 6483600  (nrow, ncol, ncell)
#> resolution : 0.1, 0.1  (x, y)
#> extent     : -0.05, 359.95, -90.05, 90.05  (xmin, xmax, ymin, ymax)
#> crs        : +proj=longlat +datum=WGS84 +no_defs
#> source     : data.nc
#> names      : X2.metre.temperature
#> z-value    : 2023-01-01
#> zvar       : t2m
