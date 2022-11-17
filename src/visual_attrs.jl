#Code for plot attributes 
using InteractiveDynamics, GLMakie, Random

Floodcolor(agent::Family) = agent.action == true ? :green : :black 
const housecolor = cgrad(:dense, 11, categorical = true)
Floodcolor(agent::House) =  housecolor[Int64(sum(agent.flood_mem)+1)]

Floodshape(agent::Family) = '⌂'
Floodsize(agent::Family) = 50
Floodshape(agent::House) = '■'
Floodsize(agent::House) = 75,75

plotsched = Schedulers.ByType(true, true, Union{House,Family})

plotkwargs = (;
ac = Floodcolor, 
as =Floodsize, 
am = Floodshape,
scheduler = plotsched, 
scatterkwargs = (strokewidth = 1.0,)
)