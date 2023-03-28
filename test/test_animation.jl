include("../src/base_model.jl")
include("../src/visual_attrs.jl")
include("../src/animation_interact.jl")

risk_abm_100_high = flood_ABM(Elevation; levee = 1/100)

anim_video("test/Test_visuals/levee_high_abm.gif", risk_abm_100_high,
agent_step!, model_step!; title = "Flood ABM", spf = 1, framerate = 3, frames = 49, showstep = true, figure = (resolution = (1450,1450),), plotkwargs...)