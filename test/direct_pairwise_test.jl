using PlanetSim

# Create a simlation environment

sim = initialize_simulation(500.0, 2.95912208286e-4)

# Add planets
add_planet!(sim, Planet("Sun", 1.00000597682, [0.0, 0.0, 0.0], [0.0, 0.0, 0.0]))
add_planet!(sim, Planet("Jupiter", 0.000954786104043, [-3.5023653, -3.8169847, -1.5507963], [0.00565429, -0.0041249, -0.00190589]))
add_planet!(sim, Planet("Saturn", 0.000285583733151, [9.0755314, -3.0458353, -1.6483708], [0.00168318, 0.00483525, 0.00192462]))
add_planet!(sim, Planet("Uranus", 0.0000437273164546, [8.310142, -16.2901086, -7.2521278], [0.00354178, 0.00137102, 0.00055029]))
add_planet!(sim, Planet("Neptune", 0.0000517759138449, [11.4707666, -25.7294829, -10.8169456], [0.0028893, 0.00114527, 0.00039677]))
#add_planet!(sim, Planet("Pluto", 1 / 1.3e8, [-15.5387357, -25.2225594, -3.1902382], [0.00276725, -0.00170702, -0.00136504]))
#add_planet!(sim, Planet("Earth", 0.000003003, [0.999723, -0.002897, 0.0], [0.000503, 0.017201, 0.0]))

# Run the simulation
data = run_algorithm(:direct_pairwise, sim)

# Display the result

plt = Animate3D_interactive(data)

display(plt)