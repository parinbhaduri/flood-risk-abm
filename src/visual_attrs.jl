"""Code for plot attributes when visualizing spatial plots"""
using InteractiveDynamics, GLMakie, Random

Floodcolor(agent::Family) = agent.action == true ? :green : :black 
const housecolor = cgrad(:dense, 11, categorical = true)
Floodcolor(agent::House) =  housecolor[Int64(agent.flood_mem+1)]

Floodshape(agent::Family) = '⌂'
Floodsize(agent::Family) = 60
Floodshape(agent::House) = '■'
Floodsize(agent::House) = 80,80

plotsched = Schedulers.ByType(true, true, Union{House,Family})

color_kwargs = (;
colormap = housecolor)

plotkwargs = (;
ac = Floodcolor, 
as =Floodsize, 
am = Floodshape,
scheduler = plotsched,
heatarray = flood_color, 
add_colorbar = true,
heatkwargs = color_kwargs, 
scatterkwargs = (strokewidth = 1.0,)
)