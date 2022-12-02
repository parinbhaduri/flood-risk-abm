#Compare regular model run with levee inclusion
include("../src/base_model.jl")
#set seed
Random.seed!(246)
risk_abm_100_high = flood_ABM(Elev_100, 0.3, 1/100)
#low risk aversion
risk_abm_100_low = flood_ABM(Elev_100, 0.7, 1/100)

#Define params to manipulate
#params = Dict(:risk_averse => 0:0.1:1,)

#Define plot attributes
include("../src/visual_attrs.jl")

#Create interactive plot
#risk_fig_100, ax_100, abmobs_100 = abmplot(risk_abm_100;
#agent_step!, model_step!, params, plotkwargs...)
#display(risk_fig_100)

action(agent) = agent.action == true
#filter out houses
fam(agent) = agent isa Family
#count Families in floodplain
f_depth = GEV_return(1/100)
floodplain(agent) = agent.pos in Tuple.(findall(<(f_depth), Elevation))
adata = [(action, count, fam), (floodplain, count, fam)]
mdata = [:Flood_depth]

#risk_exp_fig, ax, abmobs = abmexploration(risk_abm;
#agent_step!, model_step!, params, plotkwargs..., adata, alabels = ["Action"], mdata, mlabels = ["Flood Depth"])
#display(risk_exp_fig)

#run model to gather data
using Plots
##Try ensemble run
adf_100, mdf_100 = ensemblerun!([risk_abm_100_high risk_abm_100_low], agent_step!, model_step!, 50; adata, mdata)
#plot agents deciding to move
agent_plot_100 = Plots.plot(adf_100.step, adf_100.count_action_fam, group = adf_100.ensemble, label = ["high" "low"], 
linecolor = [housecolor[6] housecolor[2]], lw = 3)
Plots.ylims!(0,80)
Plots.ylabel!("Moving Agents")

#plot agents in the floodplain
fp_plot_100 = Plots.plot(adf_100.step, adf_100.count_floodplain_fam, group = adf_100.ensemble, label = ["high" "low"], 
linecolor = [housecolor[7] housecolor[3]], lw = 3)
Plots.ylabel!("Floodplain Pop.")
Plots.ylims!(160,250)
Plots.xlabel!("Year")
#plot flood depths
model_plot_100 = Plots.plot(mdf_100.step, mdf_100.Flood_depth, group = mdf_100.ensemble,
 linecolor = [housecolor[10] housecolor[5]], lw = 3)
Plots.ylims!(0,30)
Plots.ylabel!("Flood Depth")

#create subplot
levee_results = Plots.plot(model_plot_100, agent_plot_100, fp_plot_100, layout = (3,1), legend = :outertopright, dpi = 300,size = (500,600))

savefig(levee_results, "test/Test_visuals/levee_results.png")

#Spatial Plots
Random.seed!(246)
risk_abm_100_high = flood_ABM(Elev_100, 0.3, 1/100)
step!(risk_abm_100_high, agent_step!, model_step!,25)
risk_fig_100, ax, abmobs = abmplot(risk_abm_100_high,; plotkwargs...)

display(risk_fig_100)
Makie.save("test/Test_visuals/risk_fig_100.png", risk_fig_100)