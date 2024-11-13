module PlanetSim

# Bring in each submodule
include("Core.jl")
include("PlanetManager.jl")
include("Simulation.jl")
include("Algorithms.jl")
include("Visualization.jl")

using .Core
using .PlanetManager
using .Simulation
using .Algorithms
using .Visualization


# Export essential functions and struct

export Planet, Simulation_env

export initialize_simulation

export add_planet!, remove_planet!, number_of_planets, list_vels, list_pos, list_masses

export run_algorithm

export Plot_Static, Animate3D_interactive

end
