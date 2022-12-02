#using Random, Distributions


##Create return flood depth matrix using GEV distributions

#Define parameters
const μ = 0.5
const σ = 0.8
const ξ = 0.4

#Create GEV distribution
GEV_d = GeneralizedExtremeValue(μ, σ, ξ)

#Test parameters to see if they provide proper return levels
#Define function to calculate return level
#rp is the return period expressed as fraction (ex. 1/100 = 100 -yr event)
function GEV_return(rp,mu = μ, sig = σ, xi = ξ)
    y_p = -log(1 - rp)
    z_p = mu - ((sig/xi)*(1 - y_p^(-xi)))
    return z_p
end

#Create GEV distribution from parameters
function GEV_event(rng;
    d = GEV_d) #input GEV distribution 
    flood_depth = rand(rng, d)
    return flood_depth
end

#Create flood record to read into model
gev_rng = MersenneTwister(1897)
flood_record = [GEV_event(gev_rng) for _ in 1:100]

sum(flood_record .> 12)




