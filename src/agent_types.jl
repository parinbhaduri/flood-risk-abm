
using Agents


mutable struct Family <: AbstractAgent
    id::Int64
    pos::Dims{2}
    action::Bool
    age::Int
    income::Int
    utility::Float64
    
end

mutable struct House <: AbstractAgent
    id::Int64
    pos::Dims{2}
    flood::Vector{Float64}
    flood_mem::Float64
    SqFeet::Float64
    Age::Float64
    Stories::Float64
    Baths::Float64
end
    



