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