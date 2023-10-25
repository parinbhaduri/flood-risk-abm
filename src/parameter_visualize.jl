"""Code blocks to visualize model properties"""

using GLMakie, Plots, Distributions, LinearAlgebra, DataFrames, CSV

##Graph Agent action probability
#Create function
function move_curve(x; ra = 0.3, scale = 0, base_prob = 0.025)
    if x == 0.0
        prob = base_prob
    else
        init_prob = 1/(1+ exp(-(x - ra)/(0.1 - scale))) + base_prob
        prob = init_prob > 1 ? 1 : init_prob
    end
    return prob
end

x = range(0,1, length = 100)

y = move_curve.(x; ra = 0.5)
y1 = move_curve.(x; ra = 0.3)
y2 = move_curve.(x; ra = 0.7)

#Fixed Effect Curves
y1_scale = move_curve.(x; ra = 0.3, scale = 0.03)
y2_scale = move_curve.(x; ra = 0.3, scale = 0.05)
y3_scale = move_curve.(x; ra = 0.3, scale = 0.01)
y4_scale = move_curve.(x; ra = 0.3, scale = 0.08)

log_fig = Plots.plot(x,[y1 y y2], label = ["High RA" "Medium RA" "Low RA"], lw = 3,
 legend = :outertopright)
Plots.xlabel!("Flood Events per Decade")
Plots.ylabel!("Action Probability")
savefig(log_fig, "src/Parameter_visual/log_func.png")

log_scale_fig = Plots.plot(x,[y1 y1_scale y2_scale y3_scale y4_scale], label = ["High RA" "High RA w/ fe = 0.03" "High RA w/ fe = 0.05" "High RA w/ fe = 0.01" "High RA w/ fe = 0.08"], lw = 3,
 legend = :bottomright)
Plots.xlabel!("Flood Events per Decade")
Plots.ylabel!("Action Probability")

###Create heatmap for Flood level GEV_return
figure = (; resolution=(600, 400), dpi = 300, font="CMU Serif")
#Import Elevation
include("../data/Elevation.jl")
function flood_rps(model::ABM)
    #Calculate flood returns
    flood_10 = GEV_return(1/10)
    flood_100 = GEV_return(1/100)
    flood_500 = GEV_return(1/500)
    flood_1000 = GEV_return(1/1000)
    #Create matrix 
    flood_return = zeros(30,30)
    #return_labels = ["$i-yr" for i in [10,100,500,1000]]
    flood_return[model.Elevation .<= flood_10] .= 1
    flood_return[model.Elevation .> flood_10 .&& model.Elevation .<= flood_100 ] .= 2
    flood_return[model.Elevation .> flood_100 .&& model.Elevation .<= flood_500 ] .= 3
    flood_return[model.Elevation .> flood_500 .&& model.Elevation .<= flood_1000 ] .= 4
    return flood_return
end
figure_flo_ret = Plots.heatmap(1:30,1:30, transpose(flood_return), levels = 4,
    seriescolor=reverse(palette(:Blues_4)), figure = figure)
"""
risk_abm_high = flood_ABM(;Elev = Elev_60, N = 600)
#Create Plot
plotsched = Schedulers.ByType(true, true, Union{House,Family})
plotkwargs = (;
ac = Floodcolor, 
as =Floodsize, 
am = Floodshape,
scheduler = plotsched,
heatarray = flood_rps, 
add_colorbar = true,
heatkwargs = (;
colormap = reverse(cgrad(:Blues_4, 4, categorical = true))), 
scatterkwargs = (strokewidth = 1.0,)
)

risk_fig_flood, ax, abmobs = abmplot(risk_abm_high; plotkwargs...)
#Change resolution of scene
#resize!(risk_fig.scene, (600,400))
#colsize!(risk_fig.layout, 1, Aspect(1, 1.0))
display(risk_fig)
Makie.save("src/Parameter_visual/figure_elev_agents.png", risk_fig_flood)
"""
###Create heatmap for Utility
function utility_map(model::ABM)
    #Create utility matrix
    util_mat = zeros(size(model.Elevation))
    model_houses = [n for n in allagents(model) if n isa House]
    c1 = 294707 #SqFeet coef
    c2 = 130553 #Age coef
    c3 = 128990 #Stories coef
    c4 = 154887 #Baths coef
    for house in model_houses
        house_price = c1 * house.SqFeet + c2 * house.Age + c3 * house.Stories + c4 * house.Baths
        util_mat[house.pos[1], house.pos[2]] = house_price
    end
    return util_mat
end

#test house prop csv file
house_prop = DataFrame(CSV.File("../data/house_prop_synth.csv"))
util_mat = zeros(30,30)
c1 = 294707 #SqFeet coef
c2 = 130553 #Age coef
c3 = 128990 #Stories coef
c4 = 154887 #Baths coef
for row in eachrow(house_prop)
    house_price = c1 * row.SqFeet + c2 * row.Age + c3 * row.Stories + c4 * row.Baths
    util_mat[Int(row.pos_x), Int(row.pos_y)] = house_price
end


risk_abm_high = flood_ABM(;Elev = Elev_60, N = 600)
util_mat = utility_map(risk_abm_high)

figure = (; resolution=(600, 400), dpi = 300, font="CMU Serif")
figure_utility = Plots.heatmap(1:size(util_mat)[1],1:size(util_mat)[2], transpose(util_mat),
    seriescolor=reverse(cgrad([colorant"#005F73", colorant"#0A9396", colorant"#E9D8A6", colorant"#EE9B00",colorant"#BB3E03"], [0.6,0.8])), colorbar_tickfontsize = 20, Figure = figure)

savefig(figure_utility, "src/Parameter_visual/fig_utility.png")

#Need colorbar
col_mat = rand(1:11,30,30)
fig_colbar = Plots.heatmap(1:30,1:30, col_mat,
seriescolor= housecolor, colorbar_tickfontsize = 20, Figure = figure)
savefig(fig_colbar, "src/Parameter_visual/fig_colbar.png")

#Levee Breach Probability surface
#define constants

water_level = [n for n in range(0,15,step=0.1)]

levee_fail_low = levee_breach.(water_level, n_null = 0.35)
levee_fail = levee_breach.(water_level)
levee_fail_high = levee_breach.(water_level, n_null = 0.50)

Plots.plot(water_level, levee_fail, label = false, lw = 2.5)
Plots.xlabel!("Flood Depth")
Plots.ylabel!("Failure Probability")

cgrad([colorant"#0A9396", colorant"#E9D8A6", colorant"#BB3E03"], [0.3,0.4])





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