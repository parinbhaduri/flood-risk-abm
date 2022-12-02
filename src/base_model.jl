#Import Packages
using Agents
using Random
using Statistics
using LinearAlgebra
using Distributions

#Import Elevation and Flood Matrix
include("../data/Elevation.jl")
include("../data/GEV.jl")
#Import Relevant modules
#For Agents:
include("agent_types.jl")
include("agent_step.jl")
#Define Agent Types

#using .FloodAgents


#Initialize model 
function flood_ABM(Elevation, risk_averse = 0.3,levee = nothing;  #risk_averse: Decimal between 0 and 1
    flood_depth = flood_record,
    N = 600,
    M = 30, 
    griddims = (M, M),
    seed = 1897,
)
    space = GridSpace(griddims)
    
    properties = Dict(:Elevation => Elevation, :levee => levee, :Flood_depth => flood_depth, :risk_averse => risk_averse,
     :memory => 10, :tick => 1)
    

    model = ABM(
        Union{Family,House},
        space,
        scheduler = Schedulers.ByType(true, true, Union{Family,House});
        properties = properties,
        rng = MersenneTwister(seed),
        warn = false,
    )
    #Add Agents
    for n in 1:N
        agent = Family(n, (1,1), false, rand(model.rng, 1:5), rand(model.rng, 30000:200000), 0.0)
        add_agent_single!(agent, model)
    end

    #Fill model with Houses
        #Then sample normalized values from distributions
    for p in positions(model)
        if p[1] <= 8 
            SqFeet = (500.0 + (p[2]* 120.0)) / 4100.0
            Age = 3.0 / 5.0
            Stories = 2.0 / 5.0
            Baths = 3.0 / 5.0
        elseif  p[1] > 8 && p[1] <= 16
            SqFeet = 2000.0 / 4100.0
            Age = (p[2] / 6.0) / 5.0
            Stories = 2.0/ 5.0
            Baths = 3.0/ 5.0
        elseif  p[1] > 16 && p[1] <= 23
            SqFeet = 2000.0 / 4100.0
            Age = 3.0/ 5.0
            Stories = (p[2] / 6.0) / 5.0
            Baths = 3.0/ 5.0
        else
            SqFeet = 2000.0 / 4100.0
            Age = 3.0/ 5.0
            Stories = 2.0/ 5.0
            Baths = (p[2] / 6.0) / 5.0
        end
        #create vector to hold flood events experienced by house
        floods = [0]
        flood_mem = 0.0
        #Add Agents to model
        house = House(nextid(model), p, floods, flood_mem, SqFeet, Age, Stories, Baths)
        add_agent_pos!(house, model)
    end

    return model
end


### agent and model step functions  
#using .AgentFunctions 
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
#using .ModelFunctions
include("model_step.jl")
function model_step!(model::ABM)
    model.tick += 1
    flood_GEV!(model)
    relocation!(model)
        
end


