

#Calculate flood depth and update model property
function flood_GEV!(model::ABM)
    f_d = GEV_event()
    model.Flood_depth = f_d
    push!(model.flood_record, f_d)
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
    for i in sorted_agent
        pos_ids = ids_in_position(i, model)
        sort_house = [id for id in pos_ids if model[id] isa House][1]
        #Calculate agent utility at its current location
        agent_utility = exp_utility(model[sort_house])
        #Calculate Utility across all avail_house
        avail_utility = exp_utility.(avail_house)
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
