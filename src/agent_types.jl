module FloodAgents
using Agents
export Family, House

mutable struct Family <: AbstractAgent
    id::Int64
    pos::Dims{2}
    action::Bool
    age::Int
    income::Int
end

mutable struct House <: AbstractAgent
    id::Int64
    pos::Dims{2}
    flood::Vector{Float64}
    SqFeet::Float64
    Age::Float64
    Stories::Float64
    Baths::Float64
    Utility::Float64
end
    
    
end



