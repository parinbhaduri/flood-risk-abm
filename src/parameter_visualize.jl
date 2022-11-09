using InteractiveDynamics, GLMakie, Plots, Distributions

#Graph Agent action probability
x = range(0,1, length = 100)
y = [1/(1+ exp(-10(i - 0.5))) for i in x]
y1 = [1/(1+ exp(-10(i - 0.3))) for i in x]
y2 = [1/(1+ exp(-10(i - 0.7))) for i in x]

log_fig = Plots.plot(x,[y1 y y2], label = ["Ra = 0.3" "Ra = 0.5" "Ra = 0.7"], lw = 3, legend = :outertopright)
savefig(log_fig, "log_func.jpg")







"""
model = flood_ABM(Elevation)
params = Dict(:risk_averse => 0:0.1:1,)

#groupcolor(agent) = :blue

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
"""