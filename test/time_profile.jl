#initialize model
include("../src/base_model.jl")
#Define plot attributes
include("../src/visual_attrs.jl")

using BenchmarkTools, TimerOutputs
tmr = TimerOutput()
#time ensemble run of 1000 models

#Benchmark step functions
test_model = flood_ABM(Elevation)

#Model
function time_model_step!(model::ABM)
    model.tick += 1
    @timeit tmr "flood_GEV" flood_GEV!(model)
    @timeit tmr "relocation" relocation!(model)
    @timeit tmr "pop_change" model.pop_growth > 0 && pop_change!(model)
         
end




step!(test_model, agent_step!, time_model_step!, 50, false)
show(tmr)
reset_timer!(tmr)