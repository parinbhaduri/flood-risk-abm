include("../src/base_model.jl")
include("../src/data_collect.jl")
include("../src/visual_attrs.jl")
#For Parallelization
#using Distributed
#addprocs(4, exeflags="--project=$(Base.active_project())")

#initialize model
#@everywhere include("../src/base_model.jl")
#Define plot attributes
#@everywhere include("../src/data_collect.jl")

#Create models for comparison
risk_abm_high = flood_ABM(;Elev = Elevation, levee = 1/100, breach = true, N = 1200)#, pop_growth = 0.01)
##Repeat for low risk aversion (ra = 0.7)
risk_abm_fe = flood_ABM(; Elev = Elevation, levee = 1/100, breach = true, fe =  0.03, N = 1200)#, pop_growth = 0.01)


#run model to gather data (ra = 0.3; ra = 0.7)

##Try ensemble run
adf, mdf = ensemblerun!([risk_abm_high risk_abm_fe], dummystep, combine_step!, 50; adata, mdata)
#plot agents deciding to move
agent_plot = Plots.plot(adf.step, adf.count_action_fam, group = adf.ensemble, label = ["high" "low"], 
legendfontsize = 12, linecolor = [housecolor[6] housecolor[2]], lw = 5)
#Plots.ylims!(0,80)
Plots.ylabel!("Moving Agents", pointsize = 24)

#plot agents in the floodplain
fp_plot = Plots.plot(adf.step, adf.count_floodplain_fam, group = adf.ensemble, label = ["base" "fe = 0.1"], 
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
#Plots.title!("Base Move Probability: 2.5%; N = 1200 w/ 1% growth")