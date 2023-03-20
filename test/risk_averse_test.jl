#initialize model
include("../src/base_model.jl")

#Create models for comparison
risk_abm_high = flood_ABM(Elevation)
##Repeat for low risk aversion (ra = 0.7)
risk_abm_low = flood_ABM(Elevation, 0.7)

#Define plot attributes
include("../src/visual_attrs.jl")


##Create interactive plot
#risk_fig, ax, abmobs = abmplot(risk_abm;
#agent_step!, model_step!, params, plotkwargs...)
#display(risk_fig)

##Create explore plot to gather data

#Save agent & model data to collect
adata = [(action, count, fam), (floodplain, count, fam)]
mdata = [floodepth, depth_damage]


#run model to gather data (ra = 0.3; ra = 0.7)
using Plots

##Try ensemble run
adf, mdf = ensemblerun!([risk_abm_high risk_abm_low], agent_step!, model_step!, 50, agents_first = false; adata, mdata)
#plot agents deciding to move
agent_plot = Plots.plot(adf.step, adf.count_action_fam, group = adf.ensemble, label = ["high" "low"], 
legendfontsize = 12, linecolor = [housecolor[6] housecolor[2]], lw = 5)
#Plots.ylims!(0,80)
Plots.ylabel!("Moving Agents", pointsize = 24)

#plot agents in the floodplain
fp_plot = Plots.plot(adf.step, adf.count_floodplain_fam, group = adf.ensemble, label = ["high" "low"], 
legend = :bottomright,legendfontsize = 12, linecolor = [housecolor[7] housecolor[3]], lw = 5)
Plots.ylabel!("Floodplain Pop.")
Plots.ylims!(80,240)
Plots.xlabel!("Year", pointsize = 24)
#plot flood depths
model_plot = Plots.plot(adf.step[1:51], risk_abm_high.Flood_depth[1:51], legend = false,
 linecolor = housecolor[10], lw = 5)
#Add line showing 100- yr level 
flood_100 = [GEV_return(1/100) for _ in 1:51]
Plots.plot!(adf.step[1:51],flood_100, line = :dash, lw = 3)
annotate!(32,14,Plots.text("100-year level", family="serif", pointsize = 18, color = RGB(213/255,111/255,62/255)))
#Plots.ylims!(0,30)
Plots.ylabel!("Flood Depth", pointsize = 24)

#Plot Damages 
damage_plot = Plots.scatter(mdf.floodepth, mdf.depth_damage, group = mdf.ensemble, label = ["high" "low"], 
legend = :bottomright,legendfontsize = 12, markercolor = [housecolor[7] housecolor[3]])
Plots.ylabel!("Avg. Depth Difference", pointsize = 24)
Plots.xlabel!("Return Period (Years)", pointsize = 24)
#Density plot
using StatsPlots
StatsPlots.density(mdf.depth_damage, group = mdf.ensemble, label = ["high" "low"]
,legendfontsize = 12, linecolor = [housecolor[7] housecolor[3]], lw = 3)
Plots.xlabel!("Avg. Depth Difference", pointsize = 24)
Plots.ylabel!("Probability", pointsize = 24)

#create subplot
averse_results = Plots.plot(model_plot, agent_plot, fp_plot, layout = (3,1), dpi = 300, size = (500,600))


savefig(averse_results, "test/Test_visuals/averse_results.png")

#Create subplot of flood record and depth Damages
damage_results = Plots.plot(model_plot, damage_plot, layout = (2,1), dpi = 300, size = (500,600))




##Spatial Plots
risk_abm_high = flood_ABM(Elevation)
step!(risk_abm_high, agent_step!, model_step!,10, false)
#Create Plot
risk_fig, ax, abmobs = abmplot(risk_abm_high; plotkwargs...)
#Change resolution of scene
resize!(risk_fig.scene, (1450,1450))
colsize!(risk_fig.layout, 1, Aspect(1, 1.0))
display(risk_fig)

Makie.save("test/Test_visuals/risk_fig.png", risk_fig)

