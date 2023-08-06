#Compare regular model run with levee inclusion
include("../src/base_model.jl")
#Define plot attributes
include("../src/visual_attrs.jl")

risk_abm_100_high = flood_ABM(;Elev = Elevation, levee = 1/100, breach = true, N = 1200)#, pop_growth = 0.01)
#low risk aversion
risk_abm_100_low = flood_ABM(;Elev = Elevation, risk_averse = 0.7, levee = 1/100, breach = true, N = 1200)#, pop_growth = 0.01)

#risk_exp_fig, ax, abmobs = abmexploration(risk_abm;
#agent_step!, model_step!, params, plotkwargs..., adata, alabels = ["Action"], mdata, mlabels = ["Flood Depth"])
#display(risk_exp_fig)

#run model to gather data

##Try ensemble run
adf_100, _ = ensemblerun!([risk_abm_100_high risk_abm_100_low], dummystep, combine_step!, 50, agents_first = false; adata)
#plot agents deciding to move
agent_plot_100 = Plots.plot(adf_100.step, adf_100.count_action_fam, group = adf_100.ensemble, label = ["high" "low"], 
legendfontsize = 12, linecolor = [housecolor[6] housecolor[2]], lw = 5)
Plots.ylims!(0,80)
Plots.ylabel!("Moving Agents", pointsize = 24)

#plot agents in the floodplain
fp_plot_100 = Plots.plot(adf_100.step, adf_100.count_floodplain_fam, group = adf_100.ensemble, label = ["high" "low"], 
legend = :bottomright, legendfontsize = 12, linecolor = [housecolor[7] housecolor[3]], lw = 5)
Plots.ylabel!("Floodplain Pop.")
Plots.ylims!(0,240)
Plots.xlabel!("Year", pointsize = 24)

#plot flood depths
#flood_depth_levee = copy(risk_abm_high.Flood_depth)
#flood_depth_levee[flood_depth_levee .< GEV_return(1/100)] .= 0
model_plot_100 = Plots.plot(adf_100.step[1:51], risk_abm_100_high.Flood_depth[1:51], legend = false,
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




###Repeat with ensemble runs
#Create model ensemble with different seeds 
models_high_100 = [flood_ABM(Elevation; levee = 1/100, breach = true, seed = i) for i in 1000:2000]
models_low_100 = [flood_ABM(Elevation; risk_averse = 0.7, levee = 1/100, breach = true, seed = i) for i in 1000:2000]
##Try ensemble run
adf_high_100, _ = ensemblerun!(models_high_100, dummystep, combine_step!, 50; adata)
adf_low_100, _ = ensemblerun!(models_low_100, dummystep, combine_step!, 50; adata)

gdf_high_100 = groupby(adf_high_100, :step)
gdf_high_100_med = combine(gdf_high_100, [:count_action_fam :count_floodplain_fam] .=> median; renamecols=false)
#Create 95% CIs
gdf_high_100_bottom = combine(gdf_high_100,[:count_action_fam :count_floodplain_fam] .=> x -> quantile(x,0.025); renamecols=false)
gdf_high_100_top = combine(gdf_high_100,[:count_action_fam :count_floodplain_fam] .=> x -> quantile(x,0.975); renamecols=false)

gdf_low_100 = groupby(adf_low_100, :step)
gdf_low_100_med = combine(gdf_low_100, [:count_action_fam :count_floodplain_fam] .=> median; renamecols=false)
#Create 95% CIs
gdf_low_100_bottom = combine(gdf_low_100,[:count_action_fam :count_floodplain_fam] .=> x -> quantile(x,0.025); renamecols=false)
gdf_low_100_top = combine(gdf_low_100,[:count_action_fam :count_floodplain_fam] .=> x -> quantile(x,0.975); renamecols=false)


#plot agents deciding to move
agent_plot_100 = Plots.plot(adf_high_100.step[1:51], [gdf_high_100_med.count_action_fam gdf_low_100_med.count_action_fam], label = ["high" "low"], 
legendfontsize = 12, linecolor = [housecolor[6] housecolor[2]], lw = 3.5)
Plots.plot!(adf_high_100.step[1:51], [gdf_high_100_bottom.count_action_fam gdf_low_100_bottom.count_action_fam], fillrange=[gdf_high_100_top.count_action_fam gdf_low_100_top.count_action_fam],
 fillalpha=0.35, alpha =0.35, color=[housecolor[6] housecolor[2]], label=false)
Plots.ylims!(0,120)
Plots.ylabel!("Moving Agents", pointsize = 24)

#plot agents in the floodplain
fp_plot_100 = Plots.plot(adf_high_100.step[1:51], [gdf_high_100_med.count_floodplain_fam gdf_low_100_med.count_floodplain_fam], label = ["high" "low"], 
legend = :bottomright,legendfontsize = 12, linecolor = [housecolor[7] housecolor[3]], lw = 3.5)
Plots.plot!(adf_high_100.step[1:51], [gdf_high_100_bottom.count_floodplain_fam gdf_low_100_bottom.count_floodplain_fam], fillrange=[gdf_high_100_top.count_floodplain_fam gdf_low_100_top.count_floodplain_fam],
 fillalpha=0.35, alpha =0.35, color=[housecolor[6] housecolor[2]], label=false)
Plots.ylabel!("Floodplain Pop.")
Plots.ylims!(0,250)
Plots.xlabel!("Year", pointsize = 24)

#plot flood depths
model_plot_100 = Plots.plot(adf_high_100.step[1:51], models_high_100[1].Flood_depth[1:51], legend = false,
 linecolor = housecolor[10], lw = 5)
 #Add line showing 100- yr level 
flood_100 = [GEV_return(1/100) for _ in 1:51]
Plots.plot!(adf_high_100.step[1:51],flood_100, line = :dash, linecolor = RGB(213/255,111/255,62/255), lw = 3)
annotate!(32,14,Plots.text("100-year level", family="serif", pointsize = 18, color = RGB(213/255,111/255,62/255)))
Plots.ylims!(0,30)
Plots.ylabel!("Flood Depth", pointsize = 24)

#create subplot
levee_ensemble_results = Plots.plot(model_plot_100, agent_plot_100, fp_plot_100, layout = (3,1), dpi = 300,size = (500,600))

savefig(levee_ensemble_results, "test/Test_visuals/levee_ensemble_breach.png")


### Create plot showing all flood records and all model revolutions
params = Dict(
    :Elev => Elevation,
    :risk_averse => [0.3, 0.7],
    :levee => 1/100,
    :breach => true,
    :N => 1200, 
    :pop_growth => 0,
    :seed => collect(range(1000,2000)), 
)
##Evolve models over different parameter combinations
adf, mdf = paramscan(params, flood_ABM; showprogress = true, adata, mdata, agent_step! = dummystep, model_step! = combine_step!, n = 50)
adf_show = filter(:seed => isequal(1897), adf)
mdf_show = filter(:seed => isequal(1897), mdf)

##Plot

#plot agents deciding to move
agent_plot = Plots.plot(adf.step, adf.count_action_fam, group = adf.risk_averse, label = false, linecolor = [housecolor[7] housecolor[3]], alpha = 0.35, lw = 1)

Plots.plot!(adf_show.step, adf_show.count_action_fam, group = adf_show.risk_averse, label = ["high" "low"], 
legendfontsize = 12, linecolor = [housecolor[6] housecolor[2]], lw = 3)
Plots.ylims!(0,300)
Plots.ylabel!("Moving Agents", pointsize = 24)

#plot agents in the floodplain
fp_plot = Plots.plot(adf.step, adf.count_floodplain_fam, group = adf.risk_averse, label = false, linecolor = [housecolor[7] housecolor[3]], alpha = 0.35, lw = 1)
Plots.plot!(adf_show.step, adf_show.count_floodplain_fam, group = adf_show.risk_averse, label = ["high" "low"], 
legend = :bottomright, legendfontsize = 12, linecolor = [housecolor[6] housecolor[2]], lw = 3)
Plots.ylabel!("Floodplain Pop.")
Plots.ylims!(0,500)
Plots.xlabel!("Year", pointsize = 24)

#plot flood depths
model_plot = Plots.plot(mdf.step[1:51051], mdf.floodepth[1:51051], legend = false, linecolor = :gray, alpha = 0.5, lw = 1)
Plots.plot!(mdf_show.step[1:51], mdf_show.floodepth[1:51], legend = false,
 linecolor = housecolor[10], lw = 3)
#Add line showing 100- yr level 
flood_100 = [GEV_return(1/100) for _ in 1:51]
Plots.plot!(mdf_show.step[1:51],flood_100, line = :dash, linecolor = RGB(213/255,111/255,62/255), lw = 3)
annotate!(32,14,Plots.text("100-year level", family="serif", pointsize = 18, color = RGB(213/255,111/255,62/255)))
Plots.ylims!(0,40)
Plots.ylabel!("Flood Depth", pointsize = 24)

#create subplot
levee_real = Plots.plot(model_plot, agent_plot, fp_plot, layout = (3,1), dpi = 300, size = (500,600))

savefig(levee_real, "test/Test_visuals/levee_realizations.png")