using GLMakie
using GeometryBasics
include("src/PlanetOrbitSimulator.jl")
using .PlanetOrbitSimulator

# Set up the simulation
simu = set_Simulation(1000.0, 2.95912208286e-4)  # t_end, G

# Add planets (same as before)
add_planet!(simu, Planet("Sun", 1.00000597682, [0.0, 0.0, 0.0], [0.0, 0.0, 0.0]))
add_planet!(simu, Planet("Jupiter", 0.000954786104043, [-3.5023653, -3.8169847, -1.5507963], [0.00565429, -0.0041249, -0.00190589]))
add_planet!(simu, Planet("Saturn", 0.000285583733151, [9.0755314, -3.0458353, -1.6483708], [0.00168318, 0.00483525, 0.00192462]))
add_planet!(simu, Planet("Uranus", 0.0000437273164546, [8.310142, -16.2901086, -7.2521278], [0.00354178, 0.00137102, 0.00055029]))
add_planet!(simu, Planet("Neptune", 0.0000517759138449, [11.4707666, -25.7294829, -10.8169456], [0.0028893, 0.00114527, 0.00039677]))
add_planet!(simu, Planet("Pluto", 1 / 1.3e8, [-15.5387357, -25.2225594, -3.1902382], [0.00276725, -0.00170702, -0.00136504]))

# Run the simulation
sol, _ = run_simulation!(simu)  # We don't need u anymore

# Create a scene
scene = Scene(size = (800, 600), camera = cam3d!, show_axis = false)
fig = Figure(size = (800, 600))
ax = Axis3(fig[1, 1], aspect = :data, perspectiveness = 0.5)

# Define Sun and Planets properties
sun_radius = 0.5
planet_radii = [0.1, 0.09, 0.08, 0.07, 0.05]  # Adjust these values as needed

# Color palette for planets
planet_colors = [:orange, :brown, :cyan, :blue, :gray]

# Add Sun
mesh!(ax, Sphere(Point3f0(0), sun_radius), color = :yellow)

# Add Planets
planet_meshes = []
for i in 1:length(simu.planets)-1  # Exclude the Sun
    planet = mesh!(ax, Sphere(Point3f0(0), planet_radii[i]), color = planet_colors[i])
    push!(planet_meshes, planet)
end

# Function to update planet positions
function update_planet_positions!(planets, sol, time_index)
    for (i, planet) in enumerate(planets)
        x = sol[time_index][3i-2]  # x-coordinate for planet i
        y = sol[time_index][3i-1]  # y-coordinate for planet i
        z = sol[time_index][3i]    # z-coordinate for planet i
        translate!(planet, Point3f0(x, y, z))
    end
end

# Create an Observable for time index
time_index = Observable(1)

# Update planet positions when time index changes
on(time_index) do idx
    update_planet_positions!(planet_meshes, sol, idx)
end

# Create animation
num_frames = length(sol.t)
record(fig, "solar_system_animation.mp4", range(1, num_frames, length=300); framerate = 30) do frame
    time_index[] = round(Int, frame)
    ax.azimuth[] = 0.1frame  # Rotate the view slightly each frame
end

display(fig)