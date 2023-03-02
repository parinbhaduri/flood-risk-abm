# src

Use this folder to hold model source codes. Place documentation about the model structure in this file.

## File Summary

`agent_types.jl`

Stores agent structures and properties. Currently holds two structures of agents: Family and House. File is read during model construction to initialize agents.

`agent_step.jl`

Contains functions to dictate agent evolution. Each Agent type has a set of functions to update its properties over time. Select which functions to use from this file to define `agent_step!` in `base_model.jl`

`model_step.jl`

Contains functions to dictate model evolution. Each function takes an ABM type as its input and updates the model properties over time. Select which functions to use from this file to define `model_step!` in `base_model.jl`

`base_model.jl`

Primary file for model simulation. Contains three components: a model initialization function, agent step function, and model step function. The model initialization function (`flood_ABM`) creates the ABM object, and it takes three main inputs: an Elevation matrix (also defines the size of grid), risk aversion of population, and the presence/height of a levee. `agent_step!` and `model_step!` functions define agent and model evolutions, respectively. These functions are required for stepping through the model and performing model runs. 

`base_model_synth.jl`

Alternative model initialization file. Same structure as `base_model.jl`, but the model initialization function reads in agent property data from CSV files located in `data/`. Removes hardcoding agent attributes within initialization function.

`visual_attrs.jl`

Contains plot attributes for model visualization purposes. Holds info for spatial plots, such as color and size of agents, colormap for grid, and scheduling agent placement.
