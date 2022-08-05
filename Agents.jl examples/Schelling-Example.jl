using Agents


space = GridSpace((10,10))

mutable struct Schelling <: AbstractAgent
    id::Int
    pos::Tuple{Int, Int} #id and pos are required attributes
    group::Int #Agents belong to one of 2 groups
    happy::Bool #Whether agent is happy with neighbors or not
end

#Agent Type, chosen space, and optional model level properties (dict) 
Schelling
space
properties = Dict(:min_to_be_happy => 3)

model = AgentBasedModel(Schelling, space; properties = properties)

#scheduler tells model in what order agents are activated when the model evolution starts. 
#Here we change from fastest to randomly

scheduler = Schedulers.randomly

model = AgentBasedModel(Schelling, space; properties = properties, scheduler)

#Now to Populate model with agents. Create function to initialize model and populate with agents
##
function initialize(; N = 320, M = 20, min_to_be_happy = 3)
    #Create Model
    space = GridSpace((M,M))
    scheduler = Schedulers.randomly
    properties = Dict(:min_to_be_happy => min_to_be_happy)
    model = AgentBasedModel(Schelling, space; properties = properties, scheduler)

    #Add agents 
    for n in 1:N
        agent = Schelling(n, (1,1), n < N/2 ? 1 : 2, false)
        #Ternary operator ? = conditional statement: If expression is met return 1, else return 2
        add_agent_single!(agent, model)
        #Dicrete Space Exclusive: Add agent to random position while respecting max one agent per position rule
    end
    return model
end

model = initialize()

#Create Functions that govern the time evolution of the model> Can provide two step functions: agent_step & model_step
function agent_step!(agent, model)
    agent.happy && return # equivalent to if agent is happy; return agent (i.e. do nothing)
    #Count number of neighbors that belong to same group
    nearby_same = 0
    for neighbor in nearby_agents(agent, model) #nearby_agents return dynamic iterator of neighbors
        if agent.group == neighbor.group
            nearby_same += 1
        end
    end

    if nearby_same ≥ model.min_to_be_happy
        agent.happy = true
    else 
        move_agent_single!(agent, model) #randomly moves agent
    end
    return
end

#Step function for model
step!(model, agent_step!)

#To step through model 3 times
# step!(model, agent_step!, 3)

#If you have agent_step and model_step, you would state both function in step!. We dont have model_step, so dummystep is used
#step!(model, agent_step!, dummystep, 3)

#Specify when to terminate model
function t(model, s)
    #could write complex function to dictate when model ends, but here model ends after 3 iterations
    s == 3
end

#initialize and step through model again 
model = initialize()
step!(model, agent_step!, dummystep, t)

#Visualize model and animate time evolution, Can be used to check if model behaves as expected
using InteractiveDynamics, GLMakie, Random
model = initialize()
params = Dict(:min_to_be_happy => 0:1:8,)

groupcolor(agent) = agent.group == 1 ? :blue : :orange 


plotkwargs = (;
ac = groupcolor, 
as = 50, 
am = '⌂',
scatterkwargs = (strokewidth = 1.0,)
)

fig, ax, abmobs = abmplot(model; plotkwargs...)
display(fig)

##Create Interactive plot
fig, ax, abmobs = abmplot(model;
agent_step!, model_step! = dummystep, params, plotkwargs...)
display(fig)


#=
#Collect Data. You can collect data of anything you want using a function. Can be agent position or id too. 
x(agent) = agent.pos[1]

adata = [:group, :happy, x]

adf, model_df = run!(model, agent_step!, dummystep, 3; adata) # returns agent dataframe and model dataframe

#aggregate agent data 
using Statistics; mean
adata = [
    (:happy, sum),
    (x, mean)
]
model = initialize()
adf, _ = run!(model, agent_step!, dummystep, 3; adata)
=#