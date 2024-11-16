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

export Planet, Simulation_env, Region3D, OctreeNode3D

export initialize_simulation

export add_planet!, remove_planet!, number_of_planets, list_vels, list_pos, list_masses, update_sun_mass!

export run_algorithm

export Plot_Static, Static_interactive, Animate3D_interactive, Animate3D_GIF, save_gif

end
