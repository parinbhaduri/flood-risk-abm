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
#Define Agent Type

mutable struct HouseHold <: AbstractAgent
    id::Int
    pos::Dims{2}
    flood::Float64
    action::Bool
    age::Int
    income::Int
end

#Initialize model 
function flood_ABM(Elevation;
    N = 600,
    M = 30, 
    griddims = (M, M),
    c1 = 294707, 
    c2 = 130553, 
    c3 = 128990, 
    c4 = 154887, 
    risk_averse = 0.5, #Decimal between 0 and 1
)
    space = GridSpace(griddims)

    #Calculate Matrices of Housing Properties
    SqFeet = rand(500:4000, griddims)
    Age = rand(0:5, griddims)
    Stories = rand(1:3,griddims)
    Baths = rand(1:4, griddims)
    #Future Case: randomly generate values in separate file and save to csv file.
    #Then load properties from csv file

    properties = Dict(:Elevation => Elevation, :SqFeet => SqFeet,
     :Age => Age, :Stories => Stories, :Baths => Baths, :risk_averse => risk_averse)
     #Calculate initial utility
     init_utility = c1 * SqFeet + c2 * Age + c3 * Stories + c4 * Baths
     properties[:init_utility] = init_utility

    model = ABM(
        HouseHold,
        space;
        properties = properties,
    )

    #Add Agents
    for n in 1:N
        agent = HouseHold(n, (1,1), 0.0, false, rand(1:5), rand(30000:200000))
        add_agent_single!(agent, model)
    end

   
    return model
end

## Calculate Agent Probability to act
function agent_prob!(agent, model::ABM)
   #Calculate logistic Probability
   flood_prob = 1/(1+ exp(-10(agent.flood - 0.5)))
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
function update_utility(model::ABM)
    #Calculate new utility after flood occurs

    #create utility matrix of available cells for agent relocation
    avail_pos = zeros(30,30)
    #Iterate through empty gridspaces and add associated utility to avail_pos 
    for pos in empty_positions(model)
        avail_pos[pos...] = model.init_utility[pos...] 
    end
    return avail_pos
end 

    
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
function agent_step!(agent::HouseHold, model::ABM)
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