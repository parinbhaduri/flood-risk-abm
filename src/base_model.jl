#Import Packages
using Agents
using Random
using Statistics
using LinearAlgebra
using Distributions
using DataFrames

#Import Elevation and Flood Matrix
include("../data/Elevation.jl")
include("../data/GEV.jl")
#Import Relevant modules
#For Agents:
include("agent_types.jl")
include("agent_step.jl")

#Create struct to hold model properties
mutable struct Properties{Elev<:Matrix{Float64}, levee<:Float64, breach<:Bool, b_n<:Float64, flood_depth<:Vector{Float64}, risk_averse<:Float64, mem<:Int, fe<:Float64, 
    prob_move<:Float64, pop_growth<:Float64, tick<:Int}

    Elevation::Elev
    levee::levee
    breach::breach
    breach_null::b_n 
    Flood_depth::flood_depth
    risk_averse::risk_averse
    memory::mem
    fixed_effect::fe
    base_move::prob_move 
    pop_growth::pop_growth
    tick::tick
end

#Initialize model 
function flood_ABM(;Elev = Elevation, risk_averse = 0.3, levee = 0.0,  #risk_averse: Decimal between 0 and 1
    #flood_depth = copy(flood_record),
    breach = false, #Determine if Levee breaching is included in model
    b_n = 0.45,
    N = 1200, #Number of family agents to create 
    pop_growth = 0.0, #Population growth at each timestep. Recorded as decimal bw 0 and 1
    mem = 10, #Flood memory (must be integer)
    fe = 1.0,
    prob_move = 0.025, 
    seed = 1897,
)
    griddims = size(Elev)  #Dim of grid
    space = GridSpace(griddims)

    flood_rng = MersenneTwister(seed)
    flood_depth = [GEV_event(flood_rng) for _ in 1:100]
   
    
    
    #properties = Dict(:Elevation => Elev, :levee => levee, :breach => breach, :Flood_depth => flood_depth, :risk_averse => risk_averse,
    # :memory => 10, :pop_growth => pop_growth, :tick => 0)
    parameters = Properties(Elev, levee, breach, b_n, flood_depth, risk_averse, mem, fe, prob_move, pop_growth, 0)
    

    model = ABM(
        Union{House,Family},
        space,
        scheduler = Schedulers.ByType((House, Family), false);
        #scheduler = Schedulers.ByType(true, true, Union{House, Family});
        properties = parameters,
        rng = MersenneTwister(seed),
        warn = false,
    )
    #Add Agents
    for n in 1:N
        agent = Family(n, (1,1), false, rand(model.rng, 1:5), rand(model.rng, 30000:200000), 0.0)
        add_agent_single!(agent, model)
    end

    ## Fill model with Houses
    #create grid boundaries for housing properties
    bounds = [round(i*(griddims[1]/4)) for i in 1:4]
    #Then sample normalized values from distributions
    for p in positions(model)
        if p[1] <= bounds[1]
            SqFeet = (500.0 + (p[2]* 120.0)) / 4100.0
            Age = 3.0 / 5.0
            Stories = 2.0 / 5.0
            Baths = 3.0 / 5.0
        elseif  p[1] > bounds[1] && p[1] <= bounds[2]
            SqFeet = 2000.0 / 4100.0
            Age = (p[2] / 6.0) / 5.0
            Stories = 2.0/ 5.0
            Baths = 3.0/ 5.0
        elseif  p[1] > bounds[2] && p[1] <= bounds[3]
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
    model.pop_growth > 0 && pop_change!(model)       
end


#One stepping function when agents need to be stepped in between model stepping functions
function combine_step!(model::ABM)
    model.tick += 1
    flood_GEV!(model)
    for id in Agents.schedule(model)
        agent_step!(model[id], model)
    end
    relocation!(model)
    #increase pop every 5 years
    if model.pop_growth > 0
        model.tick % 5 == 0 && pop_change!(model)
    end
end

