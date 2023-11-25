# https://www.css.cornell.edu/faculty/dgr2/_static/files/R_html/ex_rgee.html#52_Climate_analysis
# https://csaybar.github.io/rgee-examples/
# https://epi-rgee.netlify.app/post/04_aplication/
#
# This is what I need!
# https://epi-rgee.netlify.app/demos/02_time_series/

library(rgee)

ee_Initialize()
srtm <- ee$Image("USGS/SRTMGL1_003")
