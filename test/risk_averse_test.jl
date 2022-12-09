#initialize model
include("../src/base_model.jl")

#Set Random Seed
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
#collect data
#for model
action(agent) = agent.action == true
#filter out houses
fam(agent) = agent isa Family
#count Families in floodplain
f_depth = GEV_return(1/100)
floodplain(agent) = agent.pos in Tuple.(findall(<(f_depth), Elevation))
adata = [(action, count, fam), (floodplain, count, fam)]
#mdata = [:Flood_depth]

Params = Dict(:risk_averse => 0:0.1:1,)
risk_exp_fig, ax, abmobs = abmplot(risk_abm_high;
agent_step!, model_step!, Params, plotkwargs...,)
display(risk_exp_fig)
#risk_fig, ax, abmobs = abmplot(risk_abm_high, enable_inspection = true; plotkwargs...)

#display(risk_fig)

#run model to gather data (ra = 0.3; ra = 0.7)
using Plots

##Try ensemble run
adf, _ = ensemblerun!([risk_abm_high risk_abm_low], agent_step!, model_step!, 50; adata)
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

#create subplot
averse_results = Plots.plot(model_plot, agent_plot, fp_plot, layout = (3,1), dpi = 300, size = (500,600))


savefig(averse_results, "test/Test_visuals/averse_results.png")

#Spatial Plots
#Random.seed!(246)
risk_abm_high = flood_ABM(Elevation)
step!(risk_abm_high, agent_step!, model_step!,25)
risk_fig, ax, abmobs = abmplot(risk_abm_high,; plotkwargs...)
colsize!(risk_fig.layout, 1, Aspect(1, 1.0))
display(risk_fig)
Makie.save("test/Test_visuals/risk_fig.png", risk_fig)


