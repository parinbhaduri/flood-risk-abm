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
step!(unit_model, agent_step!, model_step_unit!, 15)

include("../src/visual_attrs.jl")

unit_fig, ax, abmobs = abmplot(unit_model, enable_inspection = true ; plotkwargs...)

display(unit_fig)
#savefig(unit_fig,"test/Test_visuals/unit_model_init.png")

##Create ABM video
abmvideo("unit_test_abm.mp4", unit_model,
agent_step!, model_step!; title = "Flood ABM", showstep = true, frames = 150, plotkwargs...)
