#Import Packages
using Agents
using Random
using Statistics
using LinearAlgebra
using Distributions

#Create Elevation and Flood Matrix
Elevation = zeros(30,30)
basin = range(0, 10, length = 15)
Elevation = Elevation .+ [reverse(basin); basin]

Flood = zeros(30,30)
f_depth = range(0,5, length = 15)
Flood = Flood .+ [f_depth; reverse(f_depth)]

#Define Agent Types

mutable struct Family <: AbstractAgent
    id::Int64
    pos::Dims{2}
    action::Bool
    age::Int
    income::Int
end

mutable struct House <: AbstractAgent
    id::Int64
    pos::Dims{2}
    flood::Float64
    SqFeet::Float64
    Age::Float64
    Stories::Float64
    Baths::Float64
    Utility::Float64
end


#Initialize model 
function flood_ABM(Elevation, Flood;
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
    
    properties = Dict(:Elevation => Elevation, :Flood_depth => Flood, :risk_averse => risk_averse, :tick => 0)
    

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
        #Future Case: randomly generate House property values in separate file as distributions
        #Then sample normalized values from distributions
    for p in positions(model)
        SqFeet = float(rand(500:4000))
        Age = float(rand(0:5))
        Stories = float(rand(1:5))
        Baths = float(rand(30000:200000))
        #Calculate Initial Utility
        init_utility = c1 * SqFeet + c2 * Age + c3 * Stories + c4 * Baths
        #Add Agents to model
        house = House(nextid(model), p, 0.0, SqFeet, Age, Stories, Baths, init_utility)
        add_agent!(house, model)
    end

   
    

   
    return model
end


## Update Flooded Houses

## Calculate Agent Probability to act
function agent_prob!(agent::Family, House, model::ABM)
   #Calculate logistic Probability
   pos = agent.pos
   flood_prob = 1/(1+ exp(-10(House(pos).flood - 0.5)))
   #Input probability into Binomial Distribution 
    outcome = rand(Binomial(1,flood_prob), 1)
   #Save Binomial result as Agent property
    if outcome == 1
        agent.action = true
    end
end


## Sort agents based on income
function pop_change!(model::ABM)
    #Ultimately will add population growth methods
end

##Update Utility from Flooding
function update_utility(pos::Dims{2}, model::ABM)
    #Function updates given house and will return house id if house is empty 
    #Calculate new utility after flood occurs

    #create utility matrix of available cells for agent relocation
    avail_pos = zeros(30,30)
    #Iterate through empty gridspaces and add associated utility to avail_pos 
    for pos in empty_positions(model)
        avail_pos[pos...] = model.init_utility[pos...] 
    end
    return avail_pos
end 

##New Relocation function
function relocation!(model::ABM)
    #Filter Family agents by action = true
    sorted_agent = sort([a for a in allagents(model) if a isa Family && a.action = true], by = x -> x.income, rev = true)
    #Find available positions
    avail_house = [n for n in allagents(model) if n isa House && length(ids_in_position(n.pos, model)) < 2]
    #Find max utility and associated position


## Agent Relocation 
function relocation!(utility_matrix::Matrix, model::ABM)
    #sort agents by income 
    sorted_agent = sort(collect(allagents(model)), by = x -> x.income, rev = true)

    #Find max available utility and its position
    new_max = maximum(utility_matrix)
    best_ind = findfirst(x -> x == new_max, utility_matrix)
    #Iterate through agents
    for i in sorted_agent
        #If agent's current utility is larger than max available, skip iteration
        model.init_utility[i.pos...] > new_max && continue
        #Add agent's previous utility to utility matrix
        utility_matrix[i.pos...] = model.init_utility[i.pos...]
        #move agent to better utility location
        move_agent!(i, tuple(best_ind[1], best_ind[2]), model)

        #Remove position and update max terms
        utility_matrix[best_ind] = 0
        new_max = maximum(utility_matrix)
        best_ind = findfirst(x -> x == new_max, utility_matrix)
    end
end


    ### agent and model step functions

    #Agent_step function used to remove agents over time
function agent_step!(agent::Family, model::ABM)
        #track agent age over time
        agent.age += 1
        #Function will then remove agent using kill_agent! when age threshold is reached

end

    #model step really defines dynamic progression of simulation
function model_step!(model::ABM)
        new_utility = update_utility(model)
        relocation!(new_utility, model)
end


## Visualization 
using InteractiveDynamics, GLMakie, Random
model = flood_ABM(Elevation)
params = Dict(:risk_averse => 0:0.1:1,)

groupcolor(agent) = :blue

heatarray = :init_utility
heatkwargs = (colorrange = (1e8, 2e9), colormap = :viridis)
plotkwargs = (;
ac = groupcolor, 
as = 50, 
am = '⌂',
scatterkwargs = (strokewidth = 1.0,),
heatarray,
heatkwargs
)

fig, ax, abmobs = abmplot(model; plotkwargs...)
display(fig)

##Create Interactive plot
fig, ax, abmobs = abmplot(model;
agent_step!, model_step!, params, plotkwargs...)
display(fig)