
module AgentFunctions
#For Family

## Calculate Agent Probability to act
function agent_prob!(agent::Family, model::ABM)
    #Calculate logistic Probability
    year = model.tick
    time_back = year > 10 ? range(year, year - 10, step = -1) : range(year, 1, step = -1)
    pos_ids = ids_in_position(agent, model) #First id is Family, second is House
    flood_prob = 1/(1+ exp(-10(sum(model[pos_ids[2]].flood[time_back]) - 0.5)))
    #Input probability into Binomial Distribution 
    outcome = rand(Binomial(1,flood_prob), 1)
    #Save Binomial result as Agent property
    action = outcome == 1 ? true : false
    agent.action = action
end

function pop_change!(model::ABM)
    #Ultimately will add population growth methods
end

###For Houses

## Update Flooded Houses
function flooded!(agent::House, model::ABM)
    #See if house was flooded
    surge = model.Flood_depth > model.Elevation[agent.pos[1],agent.pos[2]] ? 1 : 0
    push!(agent.flood, surge) 
end

end
