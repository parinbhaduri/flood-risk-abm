#initialize model
include("../src/base_model.jl")
#Define plot attributes
include("../src/visual_attrs.jl")

using BenchmarkTools, TimerOutputs
tmr = TimerOutput()
com_tmr = TimerOutput()

#Benchmark step functions
test_model = flood_ABM(;Elev = Elevation)#, levee = 1/100, breach = true)




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
    model.pop_growth > 0 && pop_change!(model)
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
    
    @timeit com_tmr "relocate" relocate!(model)
    model.pop_growth > 0 && pop_change!(model)
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
@benchmark step!(test_model, $dummystep, $time_combine_step_new!, 50) setup=(test_model = flood_ABM(;Elev = Elevation, levee = 1/100, breach = true)) evals=1
