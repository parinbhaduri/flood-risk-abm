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

#Define Function to calculate return period from return level
function GEV_rp(z_p, mu = μ, sig = σ, xi = ξ)
    y_p = 1 + (xi * ((z_p - mu)/sig))
    rp = -exp(-y_p^(-1/xi)) + 1
    rp = round(rp, digits = 3)
    return 1/rp
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

##Create flood record with no floods above 100 yr

#Copy record
noflood_levee = copy(flood_record) 

noflood_levee[noflood_levee .> 12] .= 10

###Levee Breaching functions
