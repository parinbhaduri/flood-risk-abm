#Import Packages
using Agents
using Random
using Statistics
using LinearAlgebra
using Distributions

#Import Elevation and Flood Matrix
include("../data/Elevation.jl")

#Define Agent Types

using .FloodAgents


#Initialize model 
function flood_ABM(Elevation;
    flood_depth = 0,
    N = 600,
    M = 30, 
    griddims = (M, M),
    c1 = 294707, #SqFeet coef
    c2 = 130553, #Age coef
    c3 = 128990, #Stories coef
    c4 = 154887, #Baths coef
    risk_averse = 0.5, #Decimal between 0 and 1
)
    space = GridSpace(griddims)
    
    properties = Dict(:Elevation => Elevation, :Flood_depth => flood_depth, :risk_averse => risk_averse, :tick => 0)
    

    model = ABM(
        Union{Family,House},
        space,
        scheduler = Schedulers.ByType(true, true, Union{Family,House});
        properties = properties,
        warn = false,
    )
    #Add Agents
    for n in 1:N
        agent = Family(n, (1,1), false, rand(1:5), rand(30000:200000))
        add_agent_single!(agent, model)
    end

    #Fill model with Houses
        #Then sample normalized values from distributions
    for p in positions(model)
        if p[1] <= 8 
            SqFeet = 500 + (p[2]* 120)
            Age = 3.0
            Stories = 2.0
            Baths = 3.0
        elseif  p[1] > 8 && p[1] <= 16
            SqFeet = 2000.0
            Age = p[2] / 6
            Stories = 2.0
            Baths = 3.0
        elseif  p[1] > 16 && p[1] <= 23
            SqFeet = 2000.0
            Age = 3.0
            Stories = p[2] / 6
            Baths = 3.0
        else
            SqFeet = 2000.0
            Age = 3.0
            Stories = 2.0
            Baths = p[2] / 6
        end
        #create vector to hold flood events experienced by house
        floods = []
        #Calculate Initial Utility
        init_utility = c1 * SqFeet + c2 * Age + c3 * Stories + c4 * Baths
        #Add Agents to model
        house = House(nextid(model), p, floods, SqFeet, Age, Stories, Baths, init_utility)
        add_agent_pos!(house, model)
    end

    return model
end


### agent and model step functions  
using .AgentFunctions 
#For Family
function agent_step!(agent::Family, model::ABM)
    #track agent age over time
    agent_prob!(agent, model)
    agent.age += 1
    #Function will then remove agent using kill_agent! when age threshold is reached

end

#For House
function agent_step!(agent::House, model::ABM)
    flooded!(agent, model)

    
end


#model step defines dynamic progression of simulation
using .ModelFunctions

function model_step!(model::ABM)
    model.tick += 1
    relocation!(model)
    flood_GEV!(model)
        
end


