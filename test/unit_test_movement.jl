"""unit test to see how agents move without flood awareness. Agents are not triggered
to move based on flooding, nor do they factor in flood loss when deciding where to move"""

#Gather model functions
include("../src/base_model.jl")
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
    #flood_prob = 0.01
    #"""
    #Calculate flood probability based on risk averse value
    #No of Flood events not included here 
    if model.risk_averse == 0
        flood_prob = 1/(1+ exp(-20((0/mem) - 0.1)))
    elseif model.risk_averse == 1
        flood_prob = 0
    else
        flood_prob = 1/(1+ exp(-10((0/mem) - model.risk_averse)))
    end
    #"""
    #Input probability into Binomial Distribution 
    if flood_prob <= 1
    #outcome = rand(model.rng, 1)
        outcome = rand(model.rng, Binomial(1,flood_prob))
    #Save Binomial result as Agent property
        action = outcome == 1 ? true : false
        agent.action = action
    end
end

## Create Function for Family agent to calculate utility
function exp_utility_unit(house::House)
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
    flooded!(agent, model)

    
end

function relocation_noflood!(model::ABM)
    """Same as relocation! but uses above utility function for calculations"""
    #Filter Family agents by action = true
    sorted_agent = sort([a for a in allagents(model) if a isa Family && a.action == true], by = x -> x.income, rev = true)
    #Find available positions
    avail_house = [n for n in allagents(model) if n isa House && length(ids_in_position(n.pos, model)) < 2]
    for i in sorted_agent
        pos_ids = ids_in_position(i, model)
        sort_house = [id for id in pos_ids if model[id] isa House][1]
        #Calculate agent utility at its current location
        agent_utility = exp_utility_unit(model[sort_house])
        #Calculate Utility across all avail_house
        avail_utility = exp_utility_unit.(avail_house)
        #Identify house w/ max utility in avail_house
        new_max, new_pos = findmax(avail_utility)
        
        #If agent's current utility is larger than max available, skip iteration
        agent_utility > new_max && continue
        #Update agent utility
        i.utility = new_max
                
        #move agent to better utility location
        move_agent!(i, avail_house[new_pos].pos, model)
        #Remove max house from avail_house
        deleteat!(avail_house, new_pos)
        #Add agent's previous house to avail_house vector
        push!(avail_house, model[sort_house])
    end
end

function relocate_noflood!(model::ABM)
    "uses a dictionary to store house positions and utility values"
    #Filter Family agents by action = true
    sorted_agent = sort([a for a in allagents(model) if a isa Family && a.action == true], by = x -> x.income, rev = true)
    #Find available positions
    avail_house = [n for n in allagents(model) if n isa House && length(ids_in_position(n.pos, model)) < 2]
    #Calculate Utility across all avail_house
    util_dict = Dict(house.pos => exp_utility_unit(house) for house in avail_house)
    #Create dictionary to link house with utilities
    #Find max utility and associated position
    for i in sorted_agent
        #Ensure there are available houses
        if length(avail_house) == 0
            break
        end
        
        pos_ids = ids_in_position(i, model)
        sort_house = [id for id in pos_ids if model[id] isa House][1]
        #Calculate agent utility at its current location
        agent_utility = exp_utility_unit(model[sort_house])
        
        #Identify house w/ max utility in avail_house
        new_max = maximum(values(util_dict))
     
        #If agent's current utility is larger than max available, skip iteration
        agent_utility > new_max && continue
        #Update agent utility
        i.utility = new_max
                    
        #move agent to better utility location
        new_pos = [k for (k,v) in util_dict if v == new_max][1]
        move_agent!(i, new_pos, model)

        #Remove max house from avail_house
        delete!(util_dict, new_pos)
        #Add agent's previous house to avail_house vector
        util_dict[model[sort_house].pos] = agent_utility
    end
end

##Update model step
function model_step_noflood!(model::ABM)
    model.tick += 1
    flood_GEV!(model)
    relocation_noflood!(model)
    model.pop_growth > 0 && pop_change!(model)
end

function combine_step_noflood!(model::ABM)
    model.tick += 1
    flood_GEV!(model)
    for id in Agents.schedule(model)
        agent_step_unit!(model[id], model)
    end
    relocate_noflood!(model)
    model.pop_growth > 0 && pop_change!(model)
end



###run model to gather data (ra = 0.3; ra = 0.7)

##Create models
unit_model_high = flood_ABM(Elevation; risk_averse =  0.5)#; pop_growth = 0.005)
unit_model_low = flood_ABM(Elevation; risk_averse =  0.7)#, pop_growth = 0.005)
##Try ensemble run
adf, _ = ensemblerun!([unit_model_high unit_model_low], dummystep, combine_step_noflood!, 50; adata)

#plot agents deciding to move
agent_plot = Plots.plot(adf.step, adf.count_action_fam, group = adf.ensemble, label = ["high" "low"], 
legendfontsize = 12, linecolor = [housecolor[6] housecolor[2]], lw = 5)
Plots.ylims!(0,50)
Plots.ylabel!("Moving Agents", pointsize = 24)

#plot agents in the floodplain
fp_plot = Plots.plot(adf.step, adf.count_floodplain_fam, group = adf.ensemble, label = ["high" "low"], 
legend = :bottomright,legendfontsize = 12, linecolor = [housecolor[7] housecolor[3]], lw = 5)
Plots.ylabel!("Floodplain Pop.")
Plots.ylims!(80,400)
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
