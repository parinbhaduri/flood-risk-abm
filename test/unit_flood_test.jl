#initialize model
include("../src/base_model.jl")
"""Looks at agent evolution without relocation. Testing to see if flood depth
is properly read and recorded"""

#Create alternative flooding function
function flood_unit!(model::ABM)
    index = model.tick
    flood_events = [0,0,3.5,0,0,0,0,8.03,0,0,11.1,0,0,3.5,0,0]
    model.Flood_depth = flood_events[index]
end
#update model step function
function model_step_unit!(model::ABM)
    model.tick += 1
    flood_GEV!(model)
    #relocation!(model)
        
end

#Initialize model
unit_model = flood_ABM(Elevation)
step!(unit_model, agent_step!, model_step_unit!, 15)

include("../src/visual_attrs.jl")

unit_fig, ax, abmobs = abmplot(unit_model, enable_inspection = true ; plotkwargs...)

display(unit_fig)
#savefig(unit_fig,"test/Test_visuals/unit_model_init.png")

unitcolor(agent::Family) = :black 

unitcolor(agent::House) = housecolor[Int64(agent.flood_mem+1)]

kwargs_unit = (;
ac = unitcolor, 
as =Floodsize, 
am = Floodshape,
scheduler = plotsched,
heatarray = flood_color, 
add_colorbar = true,
heatkwargs = color_kwargs, 
scatterkwargs = (strokewidth = 1.0,)
)
##Create ABM video
anim_video("test/Test_visuals/unit_test_abm.gif", unit_model,
agent_step!, model_step_unit!; title = "Flood ABM", spf = 1, framerate = 3, frames = 49, showstep = true, figure = (resolution = (1450,1450),), kwargs_unit...)

