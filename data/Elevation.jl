
#Create Elevation Matrix for study area:
grid_length = 30
basin = range(0, 30, length = Int64(grid_length/2))
Elevation = zeros(grid_length, grid_length).+ [reverse(basin); basin]
