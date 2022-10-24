
module FloodDistribution
using Random, Distributions
export μ, σ, ξ
#Set seed 
Random.seed!(246)

##Create return flood depth matrix using GEV distributions

#Define parameters
const μ = 0.5
const σ = 0.8
const ξ = 0.4

#Test paramters to see if they provide proper return levels
#Define function to calculate return level
#rp is the return period expressed as fraction (ex. 1/100 = 100 -yr event)
function GEV_return(mu, sig, xi, rp)
    y_p = -log(1 - rp)
    z_p = mu - ((sig/xi)*(1 - y_p^(-xi)))
    return z_p
end

#Create GEV distribution from parameters
function GEV_event(mu = μ, sig = σ, xi = ξ)
    d = GeneralizedExtremeValue(μ, σ, ξ)
    flood_depth = rand(d)
    return flood_depth
end

end



