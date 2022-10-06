
##Create return flood depth matrix using GEV distributions

#Define parameters
μ = 0.5
σ = 1
ξ = 0.5
#Define function to calculate return level
function GEV_return(mu, sig, xi, rp)
    y_p = -log(1 - rp)
    z_p = mu - (sig/xi)*(1 - y_p^(-xi))
    return z_p
end
GEV_return(μ, σ, ξ, 1/100)
#Create Return period Matrix