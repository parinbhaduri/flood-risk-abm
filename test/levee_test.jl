#Compare regular model run with levee inclusion
include("../src/base_model.jl")
risk_abm_100 = flood_ABM(Elev_100, 1/100)
#Define params to manipulate
params = Dict(:risk_averse => 0:0.1:1,)

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
agents_df, model_df = run!(risk_abm_100, agent_step!, model_step!, 50; adata, mdata)

#plot agents deciding to move
agent_plot_100 = Plots.plot(agents_df.step, agents_df.count_action_fam, lw = 3)
Plots.ylabel!("Moving Agents")
#plot agents in floodplain
fp_plot_100 = Plots.plot(agents_df.step, agents_df.count_floodplain_fam, lw = 3)
Plots.ylabel!("Floodplain Pop.")
#plot flood depths
model_plot_100 = Plots.plot(model_df.step, model_df.Flood_depth, lw = 3)
Plots.ylabel!("Flood Depth")

Plots.plot(agent_plot_100, fp_plot_100, model_plot_100, layout = (3,1))

risk_fig_100, ax, abmobs = abmplot(risk_abm_100, enable_inspection = true; plotkwargs...)
display(risk_fig_100)