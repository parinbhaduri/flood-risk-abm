using InteractiveDynamics, GLMakie, Plots, Distributions, LinearAlgebra

#Graph Agent action probability
x = range(0,1, length = 100)
y = [1/(1+ exp(-10(i - 0.5))) for i in x]
y0 = [1/(1+ exp(-20(i - 0.1))) for i in x]
y1 = [1/(1+ exp(-10(i - 0.3))) for i in x]
y2 = [1/(1+ exp(-10(i - 0.7))) for i in x]
y3 = [0 for i in x]
log_fig = Plots.plot(x,[y0 y1 y y2 y3], label = ["Ra = 0" "Ra = 0.3" "Ra = 0.5" "Ra = 0.7" "Ra = 1"], lw = 3,
 legend = :outertopright)
Plots.xlabel!("Flood Events")
Plots.ylabel!("Action Probability")
savefig(log_fig, "src/Parameter_visual/log_func.png")

#Create heatmap for Flood level GEV_return
figure = (; resolution=(600, 400), dpi = 300, font="CMU Serif")
#Import Elevation
include("../data/Elevation.jl")
#Calculate flood returns
flood_10 = GEV_return(1/10)
flood_100 = GEV_return(1/100)
flood_500 = GEV_return(1/500)
flood_1000 = GEV_return(1/1000)
#Create matrix
flood_return = zeros(30,30)
#return_labels = ["$i-yr" for i in [10,100,500,1000]]
flood_return[Elevation .<= flood_10] .= 1
flood_return[Elevation .> flood_10 .&& Elevation .<= flood_100 ] .= 2
flood_return[Elevation .> flood_100 .&& Elevation .<= flood_500 ] .= 3
flood_return[Elevation .> flood_500 .&& Elevation .<= flood_1000 ] .= 4
figure_flo_ret = Plots.heatmap(1:30,1:30, transpose(flood_return), levels = 4,
    seriescolor=reverse(palette(:Blues_4)), figure = figure)
#Plots.contour(1:30,1:30, transpose(flood_return), levels = 4,
#    seriescolor=palette(:Blues_4), clabels= true, cbar = false, figure = figure)
#Colorbar(fig[1, 2], pltobj, label = "Elevation")
#colsize!(fig.layout, 1, Aspect(1, 1.0))
#fig
savefig(figure_flo_ret, "src/Parameter_visual/figure_elev.png")

##Create heatmap for Utility 
#Create utility matrix
util_mat = zeros(30,30)
model_houses = [n for n in allagents(risk_abm_high) if n isa House]
c1 = 294707 #SqFeet coef
c2 = 130553 #Age coef
c3 = 128990 #Stories coef
c4 = 154887 #Baths coef
for house in model_houses
    house_price = c1 * house.SqFeet + c2 * house.Age + c3 * house.Stories + c4 * house.Baths
    util_mat[house.pos[1], house.pos[2]] = house_price
end

figure_utility = Plots.heatmap(1:30,1:30, transpose(util_mat),
    seriescolor=reverse(cgrad(:curl, [0.6,0.8])), colorbar_tickfontsize = 20, Figure = figure)

savefig(figure_utility, "src/Parameter_visual/fig_utility.png")

#Need colorbar
col_mat = rand(1:11,30,30)
fig_colbar = Plots.heatmap(1:30,1:30, col_mat,
seriescolor= housecolor, colorbar_tickfontsize = 20, Figure = figure)
savefig(fig_colbar, "src/Parameter_visual/fig_colbar.png")
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