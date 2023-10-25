
#Create Elevation Matrix for study area:
grid_length = 44
basin = range(0, 30, length = Int64(grid_length/2))
Elevation = zeros(grid_length, grid_length).+ [reverse(basin); basin]

#Create Elevation Matrix for visualizations:
grid_length = 30
basin = range(0, 30, length = Int64(grid_length/2))
Elev_60 = zeros(grid_length, grid_length).+ [reverse(basin); basin]
"""
#Create Elevation Matrix for 100 yr event levee
include("GEV.jl")

#calculate flood depth for 100 yr event
hun_depth = GEV_return(1/100)

Elev_100 = Elevation .- hun_depth
#make neg. elev. values to 0
Elev_100[Elev_100 .< 0] .= 0
"""