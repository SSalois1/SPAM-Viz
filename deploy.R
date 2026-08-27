## Compile app and test ##
# Compile app into static assets inside the docs/ folder
shinylive::export(appdir = "app", destdir = "docs")
# test if the shapefiles load correctly in serverless environment before pushing
httpuv::runStaticServer("docs/")
