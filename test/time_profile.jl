#initialize model
include("../src/base_model.jl")
#Define plot attributes
include("../src/visual_attrs.jl")

using BenchmarkTools, TimerOutputs
tmr = TimerOutput()
com_tmr = TimerOutput()

#Benchmark step functions
test_model = flood_ABM(;Elev = Elevation, pop_growth = 0.02)#, levee = 1/100, breach = true)




#relocation
function time_combine_step_new!(model::ABM)
    model.tick += 1
    @timeit tmr "flood_GEV" flood_GEV!(model)
    @timeit tmr "agents" begin
        for id in collect(Agents.schedule(model))
            agent_step!(model[id], model)
        end
    end
    
    @timeit tmr "relocation" relocation!(model)
    @timeit tmr "pop growth" model.pop_growth > 0 && pop_change!(model)
end


#relocate
function time_combine_step!(model::ABM)
    model.tick += 1
    @timeit com_tmr "flood_GEV" flood_GEV!(model)
    @timeit com_tmr "agents" begin
        for id in collect(Agents.schedule(model))
            agent_step!(model[id], model)
        end
    end
    
    @timeit com_tmr "relocate" relocation!(model)
    @timeit com_tmr "pop growth" model.pop_growth > 0 && pop_change!(model)
end

#test new combine step
step!(test_model, dummystep, time_combine_step_new!, 50)
show(tmr)
reset_timer!(tmr)

#time original combine_step
step!(test_model, dummystep, time_combine_step!, 50)
show(com_tmr)
reset_timer!(com_tmr)

#Becnhmark entire step function
@benchmark step!(test_model, $dummystep, $time_combine_step_new!, 50) setup=(test_model = flood_ABM(;Elev = Elevation, levee = 1/100, breach = true, pop_growth = 0.02)) evals=1



map(collect(Agents.schedule(test_model))) do id
    agent_step!(test_model[id], test_model)
end

#test_model.tick += 1
#map(a -> agent_step!(test_model[a], test_model), collect(Agents.schedule(test_model)))