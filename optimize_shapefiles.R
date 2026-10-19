library(sf)

# 1. Read your massive spatial object
# (Assuming it's an sf object. If it's a sp/SpatialPolygons object, convert it first)
large_shapefile <- readRDS("app/data/garfo_stat_areas.rds")

# 2. Convert to the sf framework if it isn't already
large_areas_sf <- sf::st_as_sf(large_shapefile)

# 2. TURN OFF the strict spherical engine (forces R to use flat, planar math)
sf::sf_use_s2(FALSE)

# 3. FIX any existing corrupt edges or broken vertices first
valid_areas <- sf::st_make_valid(large_areas_sf)

# 4. SIMPLIFY the map lines
# (dTolerance = 0.01 strips out hidden vertices. Make this 0.02 or 0.03 for a smaller file)
simplified_areas <- sf::st_simplify(valid_areas, 
                                    preserveTopology = TRUE, 
                                    dTolerance = 0.01)

# 5. REPAIR the geometries again to fix any new issues created by the simplification
final_clean_areas <- sf::st_make_valid(simplified_areas)

# 6. TURN S2 BACK ON to restore standard R behavior
sf::sf_use_s2(TRUE)

# 7. SAVE it using maximum 'xz' web compression
saveRDS(final_clean_areas, "app/data/spam_stat_areas.rds", compress = "xz")


plot(final_clean_areas)
