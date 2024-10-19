module Sim

include("PlanetOrbitSimulator.jl")

using .PlanetOrbitSimulator
using Plots

export run
# Create a new simulation
simu = set_Simulation(400_000_000.0, 2.95912208286e-4)  # dt = 0.1, t_end = 100.0

# Add planets
add_planet!(simu, Planet("Sun", 1.00000597682, [0.0, 0.0, 0.0], [0.0, 0.0, 0.0]))
add_planet!(simu, Planet("Jupiter", 0.000954786104043, [-3.5023653, -3.8169847, -1.5507963], [0.00565429, -0.0041249, -0.00190589]))
add_planet!(simu, Planet("Saturn", 0.000285583733151, [9.0755314, -3.0458353, -1.6483708], [0.00168318, 0.00483525, 0.00192462]))
add_planet!(simu, Planet("Uranus", 0.0000437273164546, [8.310142, -16.2901086, -7.2521278], [0.00354178, 0.00137102, 0.00055029]))
add_planet!(simu, Planet("Neptune", 0.0000517759138449, [11.4707666, -25.7294829, -10.8169456], [0.0028893, 0.00114527, 0.00039677]))
add_planet!(simu, Planet("Pluto", 1 / 1.3e8, [-15.5387357, -25.2225594, -3.1902382], [0.00276725, -0.00170702, -0.00136504]))


# Run the simulation

function run()
    sol, u = run_simulation!(simu)
    plt = plot()
    for i in 1:number_of_planets(simu)
        plot!(plt, sol, idxs = (u[:, i]...,), lab = simu.planets[i].name)
    end
    plot!(plt; xlab = "x", ylab = "y", zlab = "z", title = "Outer solar system")

    display(plt)


end

end # module Sim

Sim.run()
