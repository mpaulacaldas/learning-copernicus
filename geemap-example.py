#! geemap/bin/python

# https://stackoverflow.com/a/30541898

import ee
import geemap
import geopandas as gpd
import pandas as pd

ee.Initialize()

# Load ERA5-Land
era5land = ee.ImageCollection("ECMWF/ERA5_LAND/MONTHLY_AGGR")\
             .select(["dewpoint_temperature_2m", "temperature_2m"])\
             .filter(ee.Filter.date("1990-01-01", "2021-12-31"))

# Import Lima
lima = gpd.read_file("https://github.com/healthinnovation/sdb-gpkg/raw/main/Lima_provincia.gpkg")
lima_ee = geemap.geopandas_to_ee(lima)

# Filter the images with the bounds of Lima
era5land_lima = era5land.filterBounds(lima_ee)


# First attempt -- reduce() over the image collection
#
# Creates a raster where each pixel has the average temperature across years, 
# for each band. Seems pretty useless. Following Alex's demo, I think here
# filterBounds() is not enough to actually crop to the area of Lima, so we 
# need to clip

era5land_lima_mean = era5land_lima.reduce(ee.Reducer.mean()).clip(lima_ee)
era5land_lima_mean.bandNames().getInfo()
#> ['dewpoint_temperature_2m_mean', 'temperature_2m_mean']


# Second attempt -- reduceRegion() over one image
#
# Getting closer. This returns the average temperature in Lima for a given year.
# After, it would be a matter of looping over the images, creating the data frames, 
# and storing them
# https://developers.google.com/earth-engine/apidocs/ee-image-reduceregion#colab-python

temp_1i = ee.Image(era5land_lima.first())
temp_1i_mean = temp_1i.reduceRegion(ee.Reducer.mean(), geometry = lima_ee.geometry())
temp_1i_info = temp_1i_mean.getInfo()
pd.DataFrame.from_dict(temp_1i_info, orient = "index")
#>                                   0
#> dewpoint_temperature_2m  290.145794
#> temperature_2m           293.339459


# Third attempt -- map() + reduceRegion()
#
# Define a function that calculates the zonal statistics for a given image, and 
# store the result as a property of the image. Not sure this would be the best 
# approach. Would only make sense if it is less computationally intensive than 
# the above?

def mean_lima(image):
  mean_reg = image.reduceRegion(ee.Reducer.mean(), geometry = lima_ee.geometry())
  return image.set(mean_reg)

temp_ic_mean = era5land_lima.map(mean_lima)
temp_ic_mean_1 = temp_ic_mean.first()
temp_ic_mean_1.getNumber("dewpoint_temperature_2m").getInfo()
#> 290.176592683422
