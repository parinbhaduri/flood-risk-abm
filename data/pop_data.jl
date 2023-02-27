###To recreate syntethic data into proper file formats
include("../src/base_model.jl")
using CSV, DataFrames

risk_abm_high = flood_ABM(Elevation)

#To create agent property CSV File
agent_prop = DataFrame(Age = rand(risk_abm_high.rng, 1:5, 600), Income = rand(risk_abm_high.rng, 30000:200000, 600))
CSV.write("data/agent_prop_synth.csv", agent_prop)

#To create Housing Property csv file

##Add agent Housing Properties to a df 
house_prop = DataFrame(SqFeet = zeros(900), Age = zeros(900), Stories = zeros(900), Baths = zeros(900), pos_x = zeros(900), pos_y = zeros(900))

model_houses = [n for n in allagents(risk_abm_high) if n isa House]

for i in 1:length(model_houses)
    house_prop[i,:] = [model_houses[i].SqFeet, model_houses[i].Age, model_houses[i].Stories, model_houses[i].Baths, model_houses[i].pos[1], model_houses[i].pos[2]]
end
#Create CSV from Housing Properties df
CSV.write("data/house_prop_synth.csv", house_prop)