# How to use Copernicus

- [Google Earth Engine](#google-earth-engine)
  - [Google Collab](#google-collab)
  - [Using R and `rgee`](#using-r-and-rgee)
  - [Using Python, with `ee` and
    `geemap`](#using-python-with-ee-and-geemap)
- [Locally](#locally)
  - [Fetching with Python’s `cdsapi`
    package](#fetching-with-pythons-cdsapi-package)
  - [Fetching and pre-processing with R’s
    `emcwfr`](#fetching-and-pre-processing-with-rs-emcwfr)
  - [Zonal statistics](#zonal-statistics)

------------------------------------------------------------------------

I want to use ERA5 Copernicus datasets to create heatstress variables
for many points or small areas (e.g. postal areas, SAU, NUTS3) across
several countries.

This is an early exploration focusing on how to *extract* some of these
metrics, in a reasonable way. My constraints are:

- I am using confidential locations and restrictedly licensed
  shapefiles.
- I am familiar with the main R spatial libraries. I can’t say the same
  for Python.
- Work relies on Windows infrastructure.

Below is a summary of the options explored, and main lessons.

## Google Earth Engine

Both
[ERA5](https://developers.google.com/earth-engine/datasets/tags/era5-land)
and
[ERA5-Land](https://developers.google.com/earth-engine/datasets/tags/era5-land)
are available in the Earth Engine Catalogue, so a colleague suggested
using Google Earth Engine to treat the datasets. I explored three ways
of doing this:

1.  Calling Earth Engine with a Google Colab notebook.
2.  Calling Earth Engine from my computer, with the
    [`ee`](https://developers.google.com/earth-engine/guides/python_install)
    Python API package.
3.  Calling Earth Engine from my computer, using R’s
    [`rgee`](https://r-spatial.github.io/rgee/) package, that wraps `ee`
    levering `reticulate`.

### Google Collab

For this experiment, I created a my own [Colab
notebook](https://colab.research.google.com/drive/1n6cFYQDVKxIGmUtNRwbpmRZ97rYxqAsK)
after going through the official Earth Engine [Colab setup
example](https://colab.research.google.com/github/google/earthengine-community/blob/master/guides/linked/ee-api-colab-setup.ipynb).
For this to work I needed to set up a Cloud Project under my own Google
account.

- Advantages: Quick, easy set-up. Fast computing.
- Disadvantages: Need to get familiar with [ee’s
  syntax](https://developers.google.com/earth-engine/apidocs/ee-image),
  and Python spatial packages.

### Using R and `rgee`

After a number of tries, I got this to work in my personal computer. I
had to sit down and go through the documentation twice, and weave
through all the vignettes. I am not confident I can get this to work in
my work laptop, since some key environment variables have been mapped to
network drives (e.g. `HOME`), and the network is quite restricted.

Also important to note that I had to set up [Google Cloud
Storage](https://r-spatial.github.io/rgee/articles/rgee05.html), provide
my credit card info, and create a project. I am working on the 300 EUR
free trial credit, but somehow already eat through 20 EUR only in the
setup.

For reference, these were the steps I followed:

<details>
<summary>Code</summary>

``` r
install.packages("rgee")

# Get the username
HOME <- Sys.getenv("HOME")

# Install miniconda
reticulate::install_miniconda()

# Get the Python bin path for miniconda
python_bin_path <- reticulate:::python_binary_path(reticulate::miniconda_path())

# Install Google Cloud SDK
system("curl -sSL https://sdk.cloud.google.com | bash")

# Get the bin path, and check if it exists
sdk_bin_path <- sprintf("%s/google-cloud-sdk/bin/", HOME)
fs::dir_exists(sdk_bin_path)

# Set global parameters
Sys.setenv("RETICULATE_PYTHON" = python_bin_path)
Sys.setenv("EARTHENGINE_GCLOUD" = sdk_bin_path)

# Install rgee Python dependencies
library(reticulate)
virtualenv_create("rgee", python = conda_python("r-reticulate"))
py_install(c("earthengine-api", "numpy", "ee_extra"), envname = "rgee")

# Add specs to `.Renviron`
rgee::ee_install_set_pyenv(
  py_path = reticulate:::virtualenv_path("rgee"),
  py_env = "rgee"
)
```

</details>

And after re-starting R:

<details>
<summary>Code</summary>

``` r
library(reticulate)
use_virtualenv("rgee")
library(rgee)

# Check credentials
ee_check_credentials()

# Install missing dependencies
install.packages("googleCloudStorageR")

# Authenticate and init your EE session
ee_Initialize(user = "mariapaulacaldas", drive = TRUE)

sak_file <- "~/Downloads/rgee-XXX.json"

# Assign the SaK to a EE user.
ee_utils_sak_copy(
  sakfile =  sak_file,
  users = "mariapaulacaldas"
)
fs::file_delete(sak_file)

# Check that we can create a bucket
project_id <- ee_get_earthengine_path() |> 
  list.files(., "\\.json$", full.names = TRUE) |> 
  jsonlite::read_json() |> 
  '$'(project_id)

googleCloudStorageR::gcs_create_bucket(
  paste0(project_id, "_bucket-001"), 
  projectId = project_id
)

# Authenticate again to check
# Authenticate and init your EE session
ee_Initialize(
  user = "mariapaulacaldas",
  drive = TRUE, 
  gcs = TRUE
)
```

</details>

Script:

- [`rgee-example.R`](rgee-exemple.R): Quick demo showing how to extract
  the average monthly temperature for areas using ERA5-Land datasets.

### Using Python, with `ee` and `geemap`

I had a go at a “pure Python” implementation. For this, I used the specs
from the virtual environment created for `rgee`, and added a couple of
extra dependencies, notably [geemap](https://geemap.org), that contains
helpers to work with `ee`.

To create the new environment:

<details>
<summary>Code</summary>

``` bash
# reticulate creates virtual environments at the user level
source ~/.virtualenvs/rgee/bin/activate
pip freeze > rgee-requirements.txt

# for the Python example, I'll put the environment in the current working 
# directory, since it's unlikely I will need to use this environment across 
# many sessions
virtualenv geemap
source geemap/bin/activate
pip install ee geemap geopandas
pip freeze > geemap-requirements.txt
```

</details>

Script:

- [`geemap-example.py`](geemap-example.py): I didn’t get as far as I
  liked exploring this option. To prepare it, I scanned through [this
  course](https://github.com/csaybar/EEwPython) and [Alex’
  demo](https://gitlab.algobank.oecd.org/Alexandre.BANQUET/oecd-earth-engine-training/-/blob/main/Urban%20Heat%20Island%20Intensity.ipynb?ref_type=heads).

## Locally

### Fetching with Python’s `cdsapi` package

For this, I registered to the [Copernicus Data
Store](https://cds.climate.copernicus.eu/user/register), created a
`.cdsapirc` key file with my uid and API key details, and installed
`cdi` under its own environment. For my work computer (Windows), I used
`Anaconda3` and `conda` to create the virtual environment, following the
instructions from the CDS website.

In my personal computer, I created the virtual environment using
`reticulate`, to make sure I use the same Python version as for `rgee`
(see above).

Overall, this wasn’t too hard, but it did require going through many
links and being careful reading the documentation.

<details>
<summary>Code</summary>

``` r
library(reticulate)
virtualenv_create("cds", python = conda_python("r-reticulate"))
py_install("cdsapi", envname = "cds")

# copy and paste the code displayed in the first block in:
# https://cds.climate.copernicus.eu/api-how-to
file.edit("~/.cdsapirc")
```

</details>

Script:

- [`cdsapi-example.py`](cdsapi-example.py): Example from the dataset
  info page.
- [`cdsapi-example.R`](cdsapi-example.R): Inspired by [Dominic Royé’s
  blog
  post](https://dominicroye.github.io/en/2018/access-to-climate-reanalysis-data-from-r/).
  Unlike the Python example, this one uses ERA5-Land hourly data on
  single levels, which are easier to iterate over.

### Fetching and pre-processing with R’s `emcwfr`

I installed the package and registered my API key details as specified
in the package README.

<details>
<summary>Code</summary>

``` r
install.packages("ecmwfr")
library("ecmwfr")
wf_set_key(service = "cds")
```

</details>

This was the easiest set-up. I also like that it makes it easy to send
workflow requests (though these must not be as fast or reliable as EE).
I still need to test in work computer, and benchmark relative to more
ambitious requests.

Scripts:

- [`emcwfr-example.R`](emcwfr-example.R): Piecing together info from the
  package README and the first example from the [CDS Toolbox
  documentation](https://cds.climate.copernicus.eu/toolbox/doc/index.html)

### Zonal statistics

Scripts:

- [`stars-demo.md`](stars-demo.md)
