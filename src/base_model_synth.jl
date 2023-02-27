#Import Packages
using Agents
using Random, Statistics
using LinearAlgebra, Distributions
using DataFrames, CSV

#Import Elevation and Flood Matrix
include("../data/Elevation.jl")
include("../data/GEV.jl")
#Import Relevant modules
#For Agents:
include("agent_types.jl")
include("agent_step.jl")

#Set desired flood record
record = copy(flood_record)

#Import Agent Property Data
agent_prop = DataFrame(CSV.File("data/agent_prop_synth.csv"))
#Import Housing Property data
house_prop = DataFrame(CSV.File("data/house_prop_synth.csv"))

#Initialize model 
function flood_ABM(Elevation, risk_averse = 0.3,levee = nothing;  #risk_averse: Decimal between 0 and 1
    flood_depth = record,
    N = 600, #Number of family agents to create 
    griddims = size(Elevation), #Dim of grid
    agent_data = agent_prop,
    house_data = house_prop, 
    seed = 1897,
)
    space = GridSpace(griddims)
    
    properties = Dict(:Elevation => Elevation, :levee => levee, :Flood_depth => flood_depth, :risk_averse => risk_averse,
     :memory => 10, :tick => 0)
    

    model = ABM(
        Union{Family,House},
        space,
        scheduler = Schedulers.ByType(true, true, Union{Family,House});
        properties = properties,
        rng = MersenneTwister(seed),
        warn = false,
    )
    #Add Agents
    for row in eachrow(agent_data)
        Age = row.Age
        Income = row.Income
        agent = Family(nextid(model), (1,1), false, Age, Income, 0.0)
        add_agent_single!(agent, model)
    end

    #Fill model with Houses
    #Then sample normalized values from distributions
    for row in eachrow(house_data)
        SqFeet = row.SqFeet
        Age = row.Age
        Stories = row.Stories
        Baths = row.Baths
        #create vector to hold flood events experienced by house
        floods = [0]
        flood_mem = 0.0
        #Add Agents to model
        house = House(nextid(model), (Int(row.pos_x), Int(row.pos_y)), floods, flood_mem, SqFeet, Age, Stories, Baths)
        add_agent_pos!(house, model)
    end

    return model
end


### agent and model step functions  

#For Family
function agent_step!(agent::Family, model::ABM)
    agent_prob!(agent, model)
    #track agent age over time
    agent.age += 1
    #Function will then remove agent using kill_agent! when age threshold is reached
end

#For House
function agent_step!(agent::House, model::ABM)
    flooded!(agent, model)

    
end


#model step defines dynamic progression of simulation

include("model_step.jl")
function model_step!(model::ABM)
    model.tick += 1
    flood_GEV!(model)
    relocation!(model)
    
        
end


