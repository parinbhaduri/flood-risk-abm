""" Code for data collection during model runs"""
### collect data for model

action(agent) = agent.action == true
#filter out houses
fam(agent) = agent isa Family
#filter out family
house(agent) = agent isa House
#count Families in floodplain
f_depth = GEV_return(1/100)
floodplain(agent) = agent.pos in Tuple.(findall(<(f_depth), Elevation))

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
        return model.Flood_depth[model.tick]
    end
end

function model_seed(model::ABM)
    return model.rng.seed[1] % Int
end

#Count available houses in grid
#vacant(model::ABM) = length([n for n in allagents(model) if length(ids_in_position(n.pos, model)) < 2 && n isa House])

## Save agent & model data to collect
adata = [(action, count, fam), (floodplain, count, fam)]
mdata = [floodepth]
