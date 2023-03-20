#Calculate depth differences for 1000 model realizations with different seed values
#initialize model
include("../src/base_model.jl")
#Define plot attributes
include("../src/visual_attrs.jl")

mdata = [floodepth, depth_damage]

risk_abm_high = flood_ABM(Elevation)
#Create empty dataframe to store data
damage_df = init_model_dataframe(risk_abm_high, mdata)
#Create models for comparison
for seed in 1000:1005
    #Create flood record
    depth_record = [GEV_event(MersenneTwister(seed)) for _ in 1:100]
    #Intialize model
    test_model = flood_ABM(Elevation; seed = seed, flood_depth = depth_record)
    #Collect data
    _, mdf = run!(test_model, agent_step!, model_step!, 50, agents_first = false; mdata)
    append!(damage_df, mdf)
end

#Plot depth_damage values

#Density plot
using StatsPlots
StatsPlots.density(damage_df.depth_damage, legendfontsize = 12, linecolor = housecolor[7], lw = 3)
Plots.xlabel!("Avg. Depth Difference", pointsize = 24)
Plots.ylabel!("Density", pointsize = 24)