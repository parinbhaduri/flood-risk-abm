
module ModelFunctions 
#Calculate flood depth and update model property
function flood_GEV!(model::ABM)
    using .FloodDistribution
    f_d = GEV_event()
    model.Flood_depth = f_d
end
#Relocation of Family Agents

function relocation!(model::ABM)
    #Filter Family agents by action = true
    sorted_agent = sort([a for a in allagents(model) if a isa Family && a.action = true], by = x -> x.income, rev = true)
    #Find available positions
    avail_house = [n for n in allagents(model) if n isa House && length(ids_in_position(n.pos, model)) < 2]
    #Find max utility and associated position
    new_max = maximum(x -> x.Utility, avail_house)
    max_house = avail_house[findfirst(x -> x.Utility == new_max, avail_house)]
    for i in sorted_agent
        pos_ids = ids_in_position(i, model)
        #If agent's current utility is larger than max available, skip iteration
        model[pos_ids[2]].Utility > new_max && continue
        #Add agent's previous house to avail_house vector
        
        #move agent to better utility location
        move_agent!(i, tuple(best_ind[1], best_ind[2]), model)

        #Remove position and update max terms
        utility_matrix[best_ind] = 0
        new_max = maximum(utility_matrix)
        best_ind = findfirst(x -> x == new_max, utility_matrix)
    end
end

end 