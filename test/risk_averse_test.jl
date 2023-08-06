#initialize model
include("../src/base_model.jl")
#Define plot attributes
include("../src/visual_attrs.jl")

#Create models for comparison
risk_abm_high = flood_ABM(; N = 1200)#, pop_growth = 0.01)
##Repeat for low risk aversion (ra = 0.7)
risk_abm_low = flood_ABM(; risk_averse =  0.7, N = 1200)#, pop_growth = 0.01)


#run model to gather data (ra = 0.3; ra = 0.7)

##Try ensemble run
adf, mdf = ensemblerun!([risk_abm_high risk_abm_low], dummystep, combine_step!, 50; adata, mdata)
#plot agents deciding to move
agent_plot = Plots.plot(adf.step, adf.count_action_fam, group = adf.ensemble, label = ["high" "low"], 
legendfontsize = 12, linecolor = [housecolor[6] housecolor[2]], lw = 5)
#Plots.ylims!(0,80)
Plots.ylabel!("Moving Agents", pointsize = 24)

#plot agents in the floodplain
fp_plot = Plots.plot(adf.step, adf.count_floodplain_fam, group = adf.ensemble, label = ["high" "low"], 
legend = :bottomright,legendfontsize = 12, linecolor = [housecolor[7] housecolor[3]], lw = 5)
Plots.ylabel!("Floodplain Pop.")
#Plots.ylims!(0,240)
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
Plots.title!("Base Move Probability: 2.5%; N = 1200 w/ 1% growth")


savefig(averse_results, "test/Test_visuals/averse_results.png")

#Create subplot of flood record and depth Damages
damage_results = Plots.plot(model_plot, damage_plot, layout = (2,1), dpi = 300, size = (500,600))


##Spatial Plots
risk_abm_high = flood_ABM(Elevation)
step!(risk_abm_high, agent_step!, model_step!,12, false)
#Create Plot
risk_fig, ax, abmobs = abmplot(risk_abm_high; plotkwargs...)
#Change resolution of scene
resize!(risk_fig.scene, (1450,1450))
colsize!(risk_fig.layout, 1, Aspect(1, 1.0))
display(risk_fig)

Makie.save("test/Test_visuals/risk_fig.png", risk_fig)



### Repeat Above with ensemble runs to create credible intervals

#Create model ensemble with different seeds 
models_high = [flood_ABM(Elevation; seed = i) for i in 1000:2000]
models_low = [flood_ABM(Elevation; risk_averse = 0.7, seed = i) for i in 1000:2000]
##Try ensemble run
adf_high, _ = ensemblerun!(models_high, dummystep, combine_step!, 50, agents_first = false; adata)
adf_low, _ = ensemblerun!(models_low, dummystep, combine_step!, 50, agents_first = false; adata)

gdf_high = groupby(adf_high, :step)
gdf_high_med = combine(gdf_high, [:count_action_fam :count_floodplain_fam] .=> median; renamecols=false)
#Create 95% CIs
gdf_high_25 = combine(gdf_high,[:count_action_fam :count_floodplain_fam] .=> x -> quantile(x,0.025); renamecols=false)
gdf_high_975 = combine(gdf_high,[:count_action_fam :count_floodplain_fam] .=> x -> quantile(x,0.975); renamecols=false)

gdf_low = groupby(adf_low, :step)
gdf_low_med = combine(gdf_low, [:count_action_fam :count_floodplain_fam] .=> median; renamecols=false)
#Create 95% CIs
gdf_low_25 = combine(gdf_low,[:count_action_fam :count_floodplain_fam] .=> x -> quantile(x,0.025); renamecols=false)
gdf_low_975 = combine(gdf_low,[:count_action_fam :count_floodplain_fam] .=> x -> quantile(x,0.975); renamecols=false)

#plot agents deciding to move
agent_plot = Plots.plot(adf_high.step[1:51], [gdf_high_med.count_action_fam gdf_low_med.count_action_fam], label = ["high" "low"], 
legendfontsize = 12, linecolor = [housecolor[6] housecolor[2]], lw = 3.5)
Plots.plot!(adf_high.step[1:51], [gdf_high_25.count_action_fam gdf_low_25.count_action_fam], fillrange=[gdf_high_975.count_action_fam gdf_low_975.count_action_fam],
 fillalpha=0.35, alpha =0.35, color=[housecolor[6] housecolor[2]], label=false)
#Plots.ylims!(0,80)
Plots.ylabel!("Moving Agents", pointsize = 24)

#plot agents in the floodplain
fp_plot = Plots.plot(adf_high.step[1:51], [gdf_high_med.count_floodplain_fam gdf_low_med.count_floodplain_fam], label = ["high" "low"], 
legend = :bottomright,legendfontsize = 12, linecolor = [housecolor[7] housecolor[3]], lw = 3.5)
Plots.plot!(adf_high.step[1:51], [gdf_high_25.count_floodplain_fam gdf_low_25.count_floodplain_fam], fillrange=[gdf_high_975.count_floodplain_fam gdf_low_975.count_floodplain_fam],
 fillalpha=0.35, alpha =0.35, color=[housecolor[6] housecolor[2]], label=false)
Plots.ylabel!("Floodplain Pop.")
Plots.ylims!(0,250)
Plots.xlabel!("Year", pointsize = 24)
#plot flood depths
model_plot = Plots.plot(adf_high.step[1:51], models_high[1].Flood_depth[1:51], legend = false,
 linecolor = housecolor[10], lw = 5)
#Add line showing 100- yr level 
flood_100 = [GEV_return(1/100) for _ in 1:51]
Plots.plot!(adf_high.step[1:51],flood_100, line = :dash, lw = 3)
annotate!(32,14,Plots.text("100-year level", family="serif", pointsize = 18, color = RGB(213/255,111/255,62/255)))
#Plots.ylims!(0,30)
Plots.ylabel!("Flood Depth", pointsize = 24)

#create subplot
averse_ensemble_results = Plots.plot(model_plot, agent_plot, fp_plot, layout = (3,1), dpi = 300, size = (500,600))

savefig(averse_ensemble_results, "test/Test_visuals/averse_ensemble.png")



### Create plot showing all flood records and all model revolutions
params = Dict(
    :Elev => Elevation,
    :risk_averse => [0.3, 0.7],
    :levee => nothing,
    :breach => false,
    :N => 1200, 
    :pop_growth => 0,
    :seed => collect(range(1000,2000)), 
)
##create models
adf, mdf = paramscan(params, flood_ABM; showprogress = true, adata, mdata, agent_step! = dummystep, model_step! = combine_step!, n = 50)
adf_show = filter(:seed => isequal(1897), adf)
mdf_show = filter(:seed => isequal(1897), mdf)
##evolve models

##Plot

#plot agents deciding to move
agent_plot = Plots.plot(adf.step, adf.count_action_fam, group = adf.risk_averse, label = false, linecolor = [housecolor[7] housecolor[3]], alpha = 0.35, lw = 1)

Plots.plot!(adf_show.step, adf_show.count_action_fam, group = adf_show.risk_averse, label = ["high" "low"], 
legend = :topright, legendfontsize = 12, linecolor = [housecolor[6] housecolor[2]], lw = 3)
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
Plots.plot!(mdf_show.step[1:51], mdf_show.floodepth[1:51], legend = false, linecolor = housecolor[10], lw = 3)
#Add line showing 100- yr level 
flood_100 = [GEV_return(1/100) for _ in 1:51]
Plots.plot!(mdf_show.step[1:51],flood_100, line = :dash, linecolor = RGB(213/255,111/255,62/255), lw = 3)
annotate!(32,14,Plots.text("100-year level", family="serif", pointsize = 18, color = RGB(213/255,111/255,62/255)))
Plots.ylims!(0,40)
Plots.ylabel!("Flood Depth", pointsize = 24)

#create subplot
averse_real = Plots.plot(model_plot, agent_plot, fp_plot, layout = (3,1), dpi = 300, size = (500,600))

savefig(averse_real, "test/Test_visuals/averse_realizations.png")