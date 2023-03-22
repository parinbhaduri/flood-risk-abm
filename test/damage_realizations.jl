#Calculate depth differences for 1000 model realizations with different seed values
#initialize model
include("../src/base_model.jl")
#Define plot attributes
include("../src/visual_attrs.jl")

function depth_difference(model::ABM, flood_rps)
    occupied_feet = []
    for rp in flood_rps
        #Calculate flood depth for given return period, store elevations of agents in floodplain
        f_depth = GEV_return(1/rp)
        #Calculate floodplain based on flood return period 
        floodplain = Tuple.(findall(<(f_depth), model.Elevation))
        #Subtract levee height from flood depth if levee is present
        if model.levee != nothing
            depth_levee = f_depth - GEV_return(model.levee)
            f_depth = depth_levee > 0 ? depth_levee : 0
        end

        damage_agents_elev = [model.Elevation[a.pos[1], a.pos[2]] for a in allagents(model) if a isa Family && a.pos in floodplain]  
        #Subtract Agent Elevation from flood depth at given timestep
        depth_diff = f_depth .- damage_agents_elev
        #turn negative values (meaning cell is not flooded) to zero
        depth_diff[depth_diff .< 0] .= 0

        depth_diff_avg = length(depth_diff) > 0 ? sum(depth_diff) : 0
        #Add value to flood_rps
        append!(occupied_feet, depth_diff_avg)
    end
    return occupied_feet
end

risk_abm_high = flood_ABM(Elevation)
risk_abm_low = flood_ABM(Elevation; risk_averse = 0.7)

risk_abm_100_high = flood_ABM(Elevation;levee = 1/100)
risk_abm_100_low = flood_ABM(Elevation; risk_averse = 0.7, levee = 1/100)
#Run models for 50 years
_ = ensemblerun!([risk_abm_high risk_abm_low risk_abm_100_high risk_abm_100_low], agent_step!, model_step!, 50, agents_first = false)

flood_rps = range(10,1000, step = 10)
occupied_high = depth_difference(risk_abm_high, flood_rps)
occupied_high_levee = depth_difference(risk_abm_100_high, flood_rps)

occupied_low = depth_difference(risk_abm_low, flood_rps)
occupied_low_levee = depth_difference(risk_abm_100_low, flood_rps)

occupied_diff_high = occupied_high_levee - occupied_high
occupied_diff_low = occupied_low_levee - occupied_low

Plots.plot(flood_rps, [occupied_diff_high occupied_diff_low], labels = ["high" "low"], xscale = :log10)
Plots.xlabel!("Return Period")
Plots.ylabel!("Difference in Occupied-Exposure")

"""
damage_df = init_model_dataframe(risk_abm_high, mdata)

#Create empty dataframe to store data

#Create models for comparison
for seed in 1000:2000
    #Create flood record
    depth_record = [GEV_event(MersenneTwister(seed)) for _ in 1:100]
    #Intialize model
    test_model = flood_ABM(Elevation; seed = seed, flood_depth = depth_record)
    #step through model
    step!(test_model, agent_step!, model_step!, 50, agents_first = false)
    append!(damage_df, mdf)
end

#Plot depth_damage values

#Density plot
using StatsPlots
StatsPlots.density(damage_df.depth_damage, legendfontsize = 12, linecolor = housecolor[7], lw = 3)
Plots.xlabel!("Avg. Depth Difference", pointsize = 24)
Plots.ylabel!("Density", pointsize = 24)
"""