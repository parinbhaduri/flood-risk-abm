using Plots,InteractiveDynamics, GLMakie, Random

"""Code for plot attributes when visualizing spatial plots"""
Floodcolor(agent::Family) = agent.action == true ? :green : :black 
const housecolor = cgrad(:dense, 11, categorical = true)
Floodcolor(agent::House) = housecolor[Int64(agent.flood_mem+1)]

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

""" Code for data collection during model runs"""
#collect data for model

action(agent) = agent.action == true
#filter out houses
fam(agent) = agent isa Family
#count Families in floodplain
f_depth = GEV_return(1/100)
floodplain(agent) = agent.pos in Tuple.(findall(<(f_depth), Elevation))

#Save agent & model data to collect
adata = [(action, count, fam), (floodplain, count, fam)]
mdata = [floodepth, depth_damage]

#calculate relative damage in floodplain
function depth_damage(model::ABM)
    #Obtain Family agents located in floodplain
    f_depth = GEV_return(1/100)
    damage_agents_elev = [Elevation[a.pos[1], a.pos[2]] for a in allagents(model) if a isa Family && a.pos in Tuple.(findall(<(f_depth), model.Elevation))]
    #work around for initializing data collection
    if model.tick == 0
        depth_damage = zeros(length(damage_agents_elev))
    else
        #Subtract Agent Elevation from flood depth at given timestep
        depth_damage = model.Flood_depth[model.tick] .- damage_agents_elev
        #turn negative values (meaning cell is not flooded) to zero
        depth_damage[depth_damage .< 0] .= 0
    end
    return mean(depth_damage)
end

#Grab flood depths at each time step
function floodepth(model::ABM)
    if model.tick == 0
        return 0.0
    else
        return GEV_rp(model.Flood_depth[model.tick])
    end
end