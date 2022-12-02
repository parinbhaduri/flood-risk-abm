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
mdata = [:Flood_depth]

#risk_exp_fig, ax, abmobs = abmexploration(risk_abm;
#agent_step!, model_step!, params, plotkwargs..., adata, alabels = ["Action" "Floodplain"], mdata, mlabels = ["Flood Depth"])
#display(risk_exp_fig)
#risk_fig, ax, abmobs = abmplot(risk_abm_high, enable_inspection = true; plotkwargs...)

#display(risk_fig)

#run model to gather data (ra = 0.3; ra = 0.7)
using Plots

##Try ensemble run
adf, mdf = ensemblerun!([risk_abm_high risk_abm_low], agent_step!, model_step!, 50; adata, mdata)
#plot agents deciding to move
agent_plot = Plots.plot(adf.step, adf.count_action_fam, group = adf.ensemble, label = ["high" "low"], 
linecolor = [housecolor[6] housecolor[2]], lw = 3)
Plots.ylims!(0,80)
Plots.ylabel!("Moving Agents")

#plot agents in the floodplain
fp_plot = Plots.plot(adf.step, adf.count_floodplain_fam, group = adf.ensemble, label = ["high" "low"], 
linecolor = [housecolor[7] housecolor[3]], lw = 3)
Plots.ylabel!("Floodplain Pop.")
Plots.ylims!(130,250)
Plots.xlabel!("Year")
#plot flood depths
model_plot = Plots.plot(mdf.step, mdf.Flood_depth, group = mdf.ensemble,
 linecolor = [housecolor[10] housecolor[5]], lw = 3)
Plots.ylims!(0,30)
Plots.ylabel!("Flood Depth")

#create subplot
averse_results = Plots.plot(model_plot, agent_plot, fp_plot, layout = (3,1), legend = :outertopright, dpi = 300, size = (500,600))


savefig(averse_results, "test/Test_visuals/averse_results.png")

#Spatial Plots
Random.seed!(246)
risk_abm_high = flood_ABM(Elevation)
step!(risk_abm_high, agent_step!, model_step!,25)
risk_fig, ax, abmobs = abmplot(risk_abm_high,; plotkwargs...)
colsize!(risk_fig.layout, 1, Aspect(1, 1.0))
display(risk_fig)
Makie.save("test/Test_visuals/risk_fig.png", risk_fig)


for _ in 1:10
    flood_GEV!(risk_abm_high)
    println(risk_abm_high.Flood_depth)
end

for _ in 1:10
    flood_GEV!(risk_abm_low)
    println(risk_abm_low.Flood_depth)
end