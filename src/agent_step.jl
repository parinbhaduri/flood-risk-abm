
using Agents

#For Family

## Calculate Agent Probability to act
function agent_prob!(agent::Family, model::ABM)
    #Calculate logistic Probability
    year = model.tick
    mem = model.memory
    time_back = year > mem ? range(year, year - (mem-1), step = -1) : range(year, 1, step = -1)
    pos_ids = ids_in_position(agent, model) #First id is Family, second is House
    calc_house = [id for id in pos_ids if model[id] isa House][1]
    #Calculate flood probability based on risk averse value
    if model.risk_averse == 0
        flood_prob = 1/(1+ exp(-20((sum(model[calc_house].flood[time_back])/mem) - 0.1)))
    elseif model.risk_averse == 1
        flood_prob = 0
    else
        flood_prob = 1/(1+ exp(-10((sum(model[calc_house].flood[time_back])/mem) - model.risk_averse)))
    end
    #Input probability into Binomial Distribution 
    if flood_prob < 1
    #outcome = rand(model.rng, 1)
        outcome = rand(model.rng, Binomial(1,flood_prob))
    #Save Binomial result as Agent property
        action = outcome == 1 ? true : false
        agent.action = action
    end
end

## Create Function for Family agent to calculate utility
function exp_utility(house::House)
    mem = 10
    c1 = 294707 #SqFeet coef
    c2 = 130553 #Age coef
    c3 = 128990 #Stories coef
    c4 = 154887 #Baths coef

    #Calculate initial utility of house
    house_price = c1 * house.SqFeet + c2 * house.Age + c3 * house.Stories + c4 * house.Baths
    #Calculate losses from flood events

    extent = length(house.flood) #gives length of flood record for house
    time_back =  extent > mem ? range(extent, extent - (mem-1), step = -1) : range(extent, 1, step = -1)
    house_loss = 1 - (0.25 * sum(house.flood[time_back]))
    will_to_pay = house_price * house_loss
    return will_to_pay

end


#function pop_change!(model::ABM)
#    #Ultimately will add population growth methods
#end

###For Houses

## Update Flooded Houses
function flooded!(agent::House, model::ABM)
    year = model.tick
    #See if house was flooded
    surge = model.Flood_depth[year] > model.Elevation[agent.pos[1],agent.pos[2]] ? 1 : 0
    push!(agent.flood, surge) 
    #Record number of floods in the last mem years
    mem = model.memory
    time_back = year > mem ? range(year, year - (mem-1), step = -1) : range(year, 1, step = -1)
    agent.flood_mem = sum(agent.flood[time_back])
end

mem_agents = [n for n in allagents(risk_abm_high) if n isa House]
