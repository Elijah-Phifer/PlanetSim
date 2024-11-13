using PlanetSim

# Create a simlation environment

sim = initialize_simulation(500.0, 2.95912208286e-4)

Sun = Planet("Sun", 1.00000597682, [0.0, 0.0, 0.0], [0.0, 0.0, 0.0])
Mercury = Planet("Mercury", 0.0000001653, [0.3871, 0.0, 0.0], [0.0, 0.0175, 0.0])
Venus = Planet("Venus", 0.0000024478383, [0.7233, 0.0, 0.0], [0.0, 0.0130, 0.0])
Earth = Planet("Earth", 0.000003003, [0.999723, -0.002897, 0.0], [0.000503, 0.017201, 0.0])
Mars = Planet("Mars", 0.000000323, [1.52366231, 0.0, 0.0], [0.0, 0.0126, 0.0])
Jupiter = Planet("Jupiter", 0.000954786104043, [-3.5023653, -3.8169847, -1.5507963], [0.00565429, -0.0041249, -0.00190589])
Saturn = Planet("Saturn", 0.000285583733151, [9.0755314, -3.0458353, -1.6483708], [0.00168318, 0.00483525, 0.00192462])
Uranus = Planet("Uranus", 0.0000437273164546, [8.310142, -16.2901086, -7.2521278], [0.00354178, 0.00137102, 0.00055029])
Neptune = Planet("Neptune", 0.0000517759138449, [11.4707666, -25.7294829, -10.8169456], [0.0028893, 0.00114527, 0.00039677])
Pluto = Planet("Pluto", 1 / 1.3e8, [-15.5387357, -25.2225594, -3.1902382], [0.00276725, -0.00170702, -0.00136504])

# Add planets
add_planet!(sim, Sun)
add_planet!(sim, Jupiter)
add_planet!(sim, Saturn)
add_planet!(sim, Uranus)
add_planet!(sim, Neptune)
add_planet!(sim, Pluto)
add_planet!(sim, Earth)
add_planet!(sim, Mars)
add_planet!(sim, Venus)
add_planet!(sim, Mercury)

remove_planet!(sim, Pluto)
remove_planet!(sim, Earth)

# Run the simulation
data = run_algorithm(:direct_pairwise, sim)

# Display the result
plt1 = Plot_Static(data)

display(plt1)

### Uncomment the following lines to try different visualization methods #####

# plt2 = Animate3D_interactive(data)

# display(plt2)

# plt3 = Animate3D_GIF(data)

# save_gif(plt3, "test/graphs/planetary_orbits.gif")