#initialize model
include("../src/base_model.jl")

#Create alternative flooding function
function flood_unit!(model::ABM)
    index = model.tick
    flood_events = [0,0,3.5,0,0,0,0,8.03,0,0,11.1,0,0,3.5,0,0]
    model.Flood_depth = flood_events[index]
end
#update model step function
function model_step_unit!(model::ABM)
    model.tick += 1
    flood_unit!(model)
    relocation!(model)
        
end

#Initialize model
unit_model = flood_ABM(Elevation)
#Step throuqh model
step!(unit_model, agent_step!, model_step_unit!,15)

#visualize model
using InteractiveDynamics, GLMakie, Random

Floodcolor(agent::Family) = agent.action == true ? :green : :black 
const housecolor = cgrad(:dense, 11, categorical = true)
Floodcolor(agent::House) =  housecolor[Int64(sum(agent.flood_mem)+1)]

Floodshape(agent::Family) = '⌂'
Floodsize(agent::Family) = 50
Floodshape(agent::House) = '■'
Floodsize(agent::House) = 75,75

plotsched = Schedulers.ByType(true, true, Union{House,Family})

plotkwargs = (;
ac = Floodcolor, 
as =Floodsize, 
am = Floodshape,
scheduler = plotsched, 
scatterkwargs = (strokewidth = 1.0,)
)

unit_fig, ax, abmobs = abmplot(unit_model, enable_inspection = true ; plotkwargs...)

display(unit_fig)
#savefig(unit_fig,"test/Test_visuals/unit_model_init.png")

##Create ABM video
abmvideo("unit_test_abm.mp4", unit_model,
agent_step!, model_step!; title = "Flood ABM", showstep = true, frames = 150, plotkwargs...)
