
using Agents

#For Family

## Calculate Agent Probability to act
function agent_prob!(agent::Family, model::ABM)
    #Calculate logistic Probability
    year = model.tick
    mem = 10
    time_back = year > mem ? range(year, year - mem, step = -1) : range(year, 1, step = -1)
    pos_ids = ids_in_position(agent, model) #First id is Family, second is House
    calc_house = [id for id in pos_ids if model[id] isa House][1]
    flood_prob = 1/(1+ exp(-10((sum(model[calc_house].flood[time_back])/mem) - model.risk_averse)))
    #Input probability into Binomial Distribution 
    outcome = rand(Binomial(1,flood_prob), 1)
    #Save Binomial result as Agent property
    action = outcome[1] == 1 ? true : false
    agent.action = action
end

## Create Function for Family agent to calculate utility
function exp_utility(house::House)
    c1 = 294707 #SqFeet coef
    c2 = 130553 #Age coef
    c3 = 128990 #Stories coef
    c4 = 154887 #Baths coef

    #Calculate initial utility of house
    house_price = c1 * house.SqFeet + c2 * house.Age + c3 * house.Stories + c4 * house.Baths
    #Calculate losses from flood events

    extent = length(house.flood) #gives length of flood record for house
    time_back =  extent > 10 ? range(extent, extent - 10, step = -1) : range(extent, 1, step = -1)
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
    #See if house was flooded
    surge = model.Flood_depth > model.Elevation[agent.pos[1],agent.pos[2]] ? 1 : 0
    push!(agent.flood, surge) 
    #Record number of floods in the last mem years
    year = model.tick
    mem = 10
    time_back = year > mem ? range(year, year - mem, step = -1) : range(year, 1, step = -1)
    agent.flood_mem = sum(agent.flood[time_back])
end


