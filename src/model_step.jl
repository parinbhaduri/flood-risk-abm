
#levee breaching probability calculation
function levee_breach(flood_height; n_null = 0.45)
    C = 0.237
    η = flood_height
    L = 30
    n_min = 0.25
    n_max = 0.55
    n_0 = n_null

    p_0 = 2*(n_max - n_min)^-1

    G_min = C *((1-n_max)/n_max) - (η/L)
    G_0 = C *((1-n_0)/n_0) - (η/L)
    G_max = C *((1-n_min)/n_min) - (η/L)

    if G_min > 0
        pf = 0
    elseif G_min <= 0 <= G_0
        t1 = 1 + (n_0/(n_max - n_0))
        t2 = (1/(G_min + (η/L) + C)) - (1/((η/L) + C))
        t3 = (p_0 * C^2)/(2*(n_max - n_0))
        t4 = (1/(G_min + (η/L) + C)^2) - (1/((η/L) + C)^2)

        pf = (p_0 * C * t1 * t2) - (t3 * t4)

    elseif G_0 < 0 <= G_max
        t1 = n_min/(n_0 - n_min)
        t2 = (1/((η/L) + C)) - (1/(G_0 + (η/L) + C))
        t3 = (p_0 * C^2)/(2*(n_0 - n_min))
        t4 = (1/((η/L) + C)^2) - (1/(G_0 + (η/L) + C)^2)

        p_G0 = p_0 * C *(1 + (n_0/(n_max - n_0))) * ((1/(G_min + (η/L) + C)) - (1/(G_0 + (η/L) + C))) - ((p_0 * C^2)/(2*(n_max - n_0))) * ((1/(G_min + (η/L) + C)^2) - (1/(G_0 + (η/L) + C)^2))

        pf = p_G0 + (p_0 * C * t1 * t2) - (t3 * t4)
    else
        pf = 1
    end
    return pf
end

#Calculate flood depth and update model property
function flood_GEV!(model::ABM)
    if model.levee > 0
        year = model.tick
        levee_height = GEV_return(model.levee)
        flood_levee = model.Flood_depth[year] - levee_height
        if model.breach == true
            #calculate breach probability
            prob_fail = levee_breach(model.Flood_depth[year])
            #Determine if Levee Breaches
            breach_outcome = rand(model.rng, Binomial(1,prob_fail))
            flood_levee = breach_outcome == 1 ? model.Flood_depth[year] : flood_levee
        end
        model.Flood_depth[year] = flood_levee < 0 ? 0 : flood_levee
    end
end



#Relocation of Family Agents

function relocation!(model::ABM)
    
    #Filter Family agents by action = true
    sorted_agent = sort([a for a in allagents(model) if a isa Family && a.action == true], by = x -> x.income, rev = true)
    #Find available positions
    avail_house = [n for n in allagents(model) if n isa House && length(ids_in_position(n.pos, model)) < 2]
    #Find max utility and associated position
    #new_max = maximum(x -> x.Utility, avail_house)
    #max_house = avail_house[findfirst(x -> x.Utility == new_max, avail_house)]
    if length(avail_house) > 0

        for i in sorted_agent
            pos_ids = ids_in_position(i, model)
            sort_house = [id for id in pos_ids if model[id] isa House][1]
            #Calculate agent utility at its current location
            agent_utility = exp_utility(model[sort_house], model)
            #Calculate Utility across all avail_house
            avail_utility = exp_utility.(avail_house, Ref(model)) #Ref sets model as a scalar for broadcasting
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
end

##Optimize relocation function 
function relocate!(model::ABM)
    "same as relocation above, but uses a dictionary to store house positions and utility values"
    #Filter Family agents by action = true
    sorted_agent = sort([a for a in allagents(model) if a isa Family && a.action == true], by = x -> x.income, rev = true)
    #Find available positions
    avail_house = [n for n in allagents(model) if n isa House && length(ids_in_position(n.pos, model)) < 2]
    #Calculate Utility across all avail_house
    util_dict = Dict(house.pos => exp_utility(house, model) for house in avail_house)
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
        agent_utility = exp_utility(model[sort_house], model)
        
        #Identify house w/ max utility in avail_house
        new_max = maximum(values(util_dict))
     
        #If agent's current utility is larger than max available, skip iteration
        agent_utility > new_max && continue
        #Update agent utility
        i.utility = new_max
                    
        #move agent to better utility location
        new_pos = [k for (k,v) in util_dict if v == new_max][1] #Just select the first house
        move_agent!(i, new_pos, model)

        #Remove max house from avail_house
        delete!(util_dict, new_pos)
        #Add agent's previous house to avail_house vector
        util_dict[model[sort_house].pos] = agent_utility
    end
end

#Collect Flood events from House Agents
function flood_color(model::ABM)
    #create space equivalent to model
    space_size = size(model.space)
    flood_event_space = zeros(space_size[1],space_size[2])
    #Collect all Houses
    model_houses = [n for n in allagents(model) if n isa House]
    #Assign flood mem to matrix space
    for i in model_houses
        flood_event_space[i.pos[1], i.pos[2]] = Int64(i.flood_mem+1)
    end
    return flood_event_space
end
