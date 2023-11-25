# How to use Copernicus

I want to use ERA5 Copernicus datasets to create heat-stress variables for many 
points or small areas (e.g. postal areas, SAU, NUTS3) across several countries.

This is an early exploration focusing on how to _extract_ some of these metrics,
in a reasonable way. My constraints are:

- I am using confidential locations and restrictedly licensed shapefiles.
- I am familiar with the main R spatial libraries. I can't say the same for Python.
- Work relies on Windows infrastructure.

Below is a summary of the options explored, and main lessons.

## Google Earth Engine

Both [ERA5] and [ERA5-Land] are available in the Earth Engine Catalogue, so a 
colleague suggested using Google Earth Engine to treat the datasets. I explored
three ways of doing this: 

1. Calling Earth Engine with a Google Colab notebook.
1. Calling Earth Engine from my computer, with the [`ee`][ee-install] Python 
   API package.
1. Calling Earth Engine from my computer, using R's [`rgee`][rgee-readme] 
   package, that wraps `ee` levering `reticulate`.

### Google Collab

For this experiment, I created a my own [Colab notebook][my-colab] after going 
through the official Earth Engine [Colab setup example][their-colab]. For this 
to work I needed to set up a Cloud Project under my own Google account.

- Advantages: Quick, easy set-up. Fast computing.
- Disadvantages: Need to get familiar with [ee's syntax][ee-docs], and Python
  spatial packages.

### Using R and `rgee`

After a number of tries, I got this to work in my personal computer. I had to 
sit down and go through the documentation twice, and weave through all the 
vignettes. I am not confident I can get this to work in my work laptop, since 
some key environment variables have been mapped to network drives (e.g. `HOME`), 
and the network is quite restricted. 

Also important to note that I had to set up [Google Cloud Storage][cloud-storage], 
provide my credit card info, and create a project. I am working on the 300 EUR
free trial credit, but somehow already eat through 20 EUR only in the setup.

For reference, these were the steps I followed:

```r
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

And  after re-starting R:

```r
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

The script [`rgee-example.R`][rgee-example] contains a quick demo showing how 
to extract the average monthly temperature for areas using ERA5-Land datasets.

[ERA5]: https://developers.google.com/earth-engine/datasets/tags/era5-land
[ERA5-Land]: https://developers.google.com/earth-engine/datasets/tags/era5-land
[ee-install]: https://developers.google.com/earth-engine/guides/python_install
[rgee-readme]: https://r-spatial.github.io/rgee/
[rgee-example]: rgee-exemple.R
[my-colab]: https://colab.research.google.com/drive/1n6cFYQDVKxIGmUtNRwbpmRZ97rYxqAsK
[their-colab]: https://colab.research.google.com/github/google/earthengine-community/blob/master/guides/linked/ee-api-colab-setup.ipynb
[ee-docs]: https://developers.google.com/earth-engine/apidocs/ee-image
[cloud-storage]: https://r-spatial.github.io/rgee/articles/rgee05.html
