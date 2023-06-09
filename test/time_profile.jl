#initialize model
include("../src/base_model.jl")
#Define plot attributes
include("../src/visual_attrs.jl")

using BenchmarkTools, TimerOutputs
tmr = TimerOutput()
com_tmr = TimerOutput()
##Optimize relocation function 
function test_relocate!(model::ABM)
    
    #Filter Family agents by action = true
    sorted_agent = sort([a for a in allagents(model) if a isa Family && a.action == true], by = x -> x.income, rev = true)
    #Find available positions
    avail_house = [n for n in allagents(model) if n isa House && length(ids_in_position(n.pos, model)) < 2]
    #Calculate Utility across all avail_house
    util_dict = Dict(house.pos => exp_utility(house, test_model) for house in avail_house)
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
        new_pos = rand(test_model.rng, [k for (k,v) in util_dict if v == new_max])
        move_agent!(i, new_pos, model)

        #Remove max house from avail_house
        delete!(util_dict, new_pos)
        #Add agent's previous house to avail_house vector
        util_dict[model[sort_house].pos] = agent_utility
    end
end

#Benchmark step functions
test_model = flood_ABM(Elevation)

#Model
function time_model_step!(model::ABM)
    model.tick += 1
    @timeit tmr "flood_GEV" flood_GEV!(model)
    #@timeit tmr "relocation" relocation!(model)
    @timeit tmr "test relocate" test_relocate!(model)
    @timeit tmr "pop_change" model.pop_growth > 0 && pop_change!(model)
         
end


#combined
function time_combine_step!(model::ABM)
    model.tick += 1
    @timeit com_tmr "flood_GEV" flood_GEV!(model)
    @timeit com_tmr "agents" begin
        for id in Agents.schedule(test_model)
            agent_step!(model[id], model)
        end
    end
    
    @timeit com_tmr "relocate" test_relocate!(model)
    model.pop_growth > 0 && pop_change!(model)
end

#test original
step!(test_model, agent_step!, time_model_step!, 50, false)
show(tmr)
reset_timer!(tmr)

#time combine_step
step!(test_model, dummystep, time_combine_step!, 50, false)
show(com_tmr)
reset_timer!(com_tmr)

#Becnhmark entire step function
@benchmark step!(test_model, $dummystep, $time_combine_step!, 50, false) setup=(test_model = flood_ABM(Elevation)) evals=1
