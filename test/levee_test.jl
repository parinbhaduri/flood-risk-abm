#Compare regular model run with levee inclusion
include("../src/base_model.jl")
#set seed
risk_abm_100_high = flood_ABM(Elevation; levee = 1/100)
#low risk aversion
risk_abm_100_low = flood_ABM(Elevation; risk_averse = 0.7, levee = 1/100)


#Define plot attributes
include("../src/visual_attrs.jl")

adata = [(action, count, fam), (floodplain, count, fam)]
#mdata = [:Flood_depth]

#risk_exp_fig, ax, abmobs = abmexploration(risk_abm;
#agent_step!, model_step!, params, plotkwargs..., adata, alabels = ["Action"], mdata, mlabels = ["Flood Depth"])
#display(risk_exp_fig)

#run model to gather data
using Plots

##Try ensemble run
adf_100, _ = ensemblerun!([risk_abm_100_high risk_abm_100_low], agent_step!, model_step!, 50, agents_first = false; adata)
#plot agents deciding to move
agent_plot_100 = Plots.plot(adf_100.step, adf_100.count_action_fam, group = adf_100.ensemble, label = ["high" "low"], 
legendfontsize = 12, linecolor = [housecolor[6] housecolor[2]], lw = 5)
#Plots.ylims!(0,80)
Plots.ylabel!("Moving Agents", pointsize = 24)

#plot agents in the floodplain
fp_plot_100 = Plots.plot(adf_100.step, adf_100.count_floodplain_fam, group = adf_100.ensemble, label = ["high" "low"], 
legend = :bottomright, legendfontsize = 12, linecolor = [housecolor[7] housecolor[3]], lw = 5)
Plots.ylabel!("Floodplain Pop.")
Plots.ylims!(80,240)
Plots.xlabel!("Year", pointsize = 24)

#plot flood depths
flood_depth_levee = copy(risk_abm_high.Flood_depth)
flood_depth_levee[flood_depth_levee .< GEV_return(1/100)] .= 0
model_plot_100 = Plots.plot(adf_100.step[1:51], flood_depth_levee[1:51], legend = false,
 linecolor = [housecolor[10] housecolor[5]], lw = 5)
 #Add line showing 100- yr level 
flood_100 = [GEV_return(1/100) for _ in 1:51]
Plots.plot!(adf_100.step[1:51],flood_100, line = :dash, lw = 3)
annotate!(32,14,Plots.text("100-year level", family="serif", pointsize = 18, color = RGB(213/255,111/255,62/255)))
Plots.ylims!(0,30)
Plots.ylabel!("Flood Depth", pointsize = 24)

#create subplot
levee_results = Plots.plot(model_plot_100, agent_plot_100, fp_plot_100, layout = (3,1), dpi = 300,size = (500,600))

savefig(levee_results, "test/Test_visuals/levee_results.png")

#Spatial Plots

risk_abm_100_high = flood_ABM(Elev_100, 0.3, 1/100)
step!(risk_abm_100_high, agent_step!, model_step!, 25, false)
risk_fig_100, ax, abmobs = abmplot(risk_abm_100_high,; plotkwargs...)

display(risk_fig_100)
Makie.save("test/Test_visuals/risk_fig_100.png", risk_fig_100)

