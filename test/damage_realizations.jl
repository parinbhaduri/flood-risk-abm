#Calculate depth differences for 1000 model realizations with different seed values
#initialize model
include("../src/base_model.jl")
#Define plot attributes
include("../src/visual_attrs.jl")

mdata = [floodepth, depth_damage]

#Create empty dataframe to store data

#Create models for comparison
for seed in 1000:2000
    #Create flood record
    flood_record = [GEV_event(MersenneTwister(seed)) for _ in 1:100]
    #Intialize model
    test_model = flood_ABM(Elevation; seed = 1000)
    #Collect data
    _, mdf = run!(test_model, agent_step!, model_step!, 50, agents_first = false; mdata)
    append!(damage_df, mdf)
end




