## Compile app and test ##
# run the following lines to make sure you are using fonts/packages 
# that are compatible with WebAssmebly
options(timeout = 600)
options(bslib.use_google_fonts = FALSE)
# Install remotes if you don't have it already
if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes")

# Install the specific versions matching the WebAssembly repo
remotes::install_version("tinytex", version = "0.59", upgrade = "never")
remotes::install_version("xfun", version = "0.57", upgrade = "never")

# Compile app - makes static files and saves to /docs 
shinylive::export(appdir = "app", destdir = "docs")
# test if the shapefiles load correctly in serverless environment before pushing
httpuv::runStaticServer("docs/")

