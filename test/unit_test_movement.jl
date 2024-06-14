"""unit test to see how agents move without flood awareness. Agents are not triggered
to move based on flooding, nor do they factor in flood loss when deciding where to move"""

#Gather model functions
include("../src/base_model.jl")
include("../src/data_collect.jl")
include("../src/visual_attrs.jl")
#Create alternative agent step function
## Calculate Agent Probability to act
function agent_prob_unit!(agent::Family, model::ABM)
    """Function determines probability of agent action
    using a risk aversion function.
    Output updates agent's action property""" 
    #Calculate logistic Probability
    year = model.tick
    mem = model.memory
    
    pos_ids = ids_in_position(agent, model) #First id is Family, second is House
    calc_house = [id for id in pos_ids if model[id] isa House][1]
    #Define baseline probability of movement
    base_prob = model.base_move
    
    #Calculate flood probability based on risk averse value
    if model[calc_house].flood_mem == 0
        flood_prob = base_prob
    elseif model.risk_averse == 0
        #flood_prob = 1/(1+ exp(-20((sum(model[calc_house].flood[time_back])/mem) - 0.1)))
        flood_prob = 1/(1+ exp(-20((0) - 0.1)))  + base_prob
    elseif model.risk_averse == 1
        flood_prob = 0
    else
        #flood_prob = 1/(1+ exp(-10((sum(model[calc_house].flood[time_back])/mem) - model.risk_averse)))
        flood_prob = 1/(1+ exp(-10((0) - model.risk_averse))) + base_prob
    end
    #Input probability into Binomial Distribution 
    move_prob = flood_prob <= 1.0 ? flood_prob : 1
    #outcome = rand(model.rng, 1)
    outcome = rand(model.rng, Binomial(1,move_prob))
    #Save Binomial result as Agent property
    action = outcome == 1 ? true : false
    agent.action = action
end

## Create Function for Family agent to calculate utility
function exp_utility_unit(house::House, model::ABM)
    c1 = 294707 #SqFeet coef
    c2 = 130553 #Age coef
    c3 = 128990 #Stories coef
    c4 = 154887 #Baths coef

    #Calculate initial utility of house
    house_price = c1 * house.SqFeet + c2 * house.Age + c3 * house.Stories + c4 * house.Baths

    return house_price

end

#For Family
function agent_step_unit!(agent::Family, model::ABM)
    agent_prob_unit!(agent, model)
    #track agent age over time
    agent.age += 1
    #Function will then remove agent using kill_agent! when age threshold is reached
end

#For House
function agent_step_unit!(agent::House, model::ABM)
    #flood_GEV!(agent, model)
    nothing

    
end

function relocation_noflood!(model::ABM)
    """Same as relocation! but uses above utility function for calculations"""
    #Filter Family agents by action = true
    sorted_agent = sort([a for a in allagents(model) if a isa Family && a.action == true], by = x -> x.income, rev = true)
    #Find available positions
    avail_house = [n for n in allagents(model) if n isa House && length(ids_in_position(n.pos, model)) < 2]
    #Store available positions and associated utility in array 
    house_df = DataFrame(pos = [house.pos for house in avail_house], utility = [exp_utility_unit(house, model) for house in avail_house])
    sort!(house_df, :utility, rev = true)
    
    for agent in sorted_agent
        #Ensure there are available houses
        if length(house_df[:,1]) == 0
            break
        end
        pos_ids = ids_in_position(agent, model)
        curr_house = [model[id] for id in pos_ids if model[id] isa House][1]
        #Calculate agent utility at its current location
        curr_utility = exp_utility_unit(curr_house, model)
        #If agent's current utility is larger than max available, skip iteration
        curr_utility > house_df[1, :utility] && continue
        #move agent to better utility location
        move_agent!(agent, house_df[1, :pos], model)
        #Update agent utility
        agent.utility = house_df[1, :utility]
        #Remove moved into house from house_df
        popfirst!(house_df)
        #Add agent's previous house to house_df
        insert!(house_df, searchsortedfirst(house_df[!, :utility], curr_utility, rev = true), (curr_house.pos, curr_utility))
    end
end


function combine_step_noflood!(model::ABM)
    model.tick += 1
    flood_GEV!(model)
    for id in Agents.schedule(model)
        agent_step_unit!(model[id], model)
    end
    relocation_noflood!(model)
    model.pop_growth > 0 && pop_change!(model)
end



###run model to gather data (ra = 0.3; ra = 0.7)

##Create models
unit_model_high = flood_ABM(;Elev = Elevation, levee = 1/100, breach = true, N = 1200)#; pop_growth = 0.005)
unit_model_low = flood_ABM(;Elev = Elevation, levee = 1/100, breach = true, risk_averse = 0.7, N = 1200)#, pop_growth = 0.005)
##Try ensemble run
adf, _ = ensemblerun!([unit_model_high unit_model_low], dummystep, combine_step_noflood!, 50; adata)

#plot agents deciding to move
agent_plot = Plots.plot(adf.step, adf.count_action_fam, group = adf.ensemble, label = ["high" "low"], 
legendfontsize = 12, linecolor = [housecolor[6] housecolor[2]], lw = 5)
#Plots.ylims!(0,50)
Plots.ylabel!("Moving Agents", pointsize = 24)

#plot agents in the floodplain
fp_plot = Plots.plot(adf.step, adf.count_floodplain_fam, group = adf.ensemble, label = ["high" "low"], 
legend = :bottomright,legendfontsize = 12, linecolor = [housecolor[7] housecolor[3]], lw = 5)
Plots.ylabel!("Floodplain Pop.")
#Plots.ylims!(80,400)
Plots.xlabel!("Year", pointsize = 24)
#plot flood depths
model_plot = Plots.plot(adf.step[1:51], unit_model_high.Flood_depth[1:51], legend = false,
 linecolor = housecolor[10], lw = 5)
#Add line showing 100- yr level 
flood_100 = [GEV_return(1/100) for _ in 1:51]
Plots.plot!(adf.step[1:51],flood_100, line = :dash, lw = 3)
annotate!(32,14,Plots.text("100-year level", family="serif", pointsize = 18, color = RGB(213/255,111/255,62/255)))
Plots.ylims!(0,30)
Plots.ylabel!("Flood Depth", pointsize = 24)

#create subplot
averse_results = Plots.plot(model_plot, agent_plot, fp_plot, layout = (3,1), dpi = 300, size = (500,600))


#Visualize model
unit_model = flood_ABM(Elevation)

#step!(unit_model, agent_step_unit!, model_step_noflood!, 15)

unit_fig, ax, abmobs = abmplot(unit_model; agent_step! = dummystep, model_step! = combine_step!,
enable_inspection = true, figure = (resolution = (1450,1450),), plotkwargs...)

display(unit_fig)


adata = [(action, count, fam), (floodplain, count, fam)]
#mdata = [:Flood_depth]
