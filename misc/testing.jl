using GLMakie

# Create a scene
scene = Scene(size = (800, 600), camera = cam3d!, show_axis = false)

# Define Sun and Planets properties
sun_radius = 0.1
planet_radii = [0.02, 0.03, 0.04]  # Example planet radii
orbital_distances = [1.0, 1.5, 2.0]  # Example orbital distances from the Sun

# Add Sun
mesh!(scene, Sphere(Point3f0(0), sun_radius), color = :yellow)

# Add Planets (initial positions)
planet_meshes = []
for i in 1:length(planet_radii)
    planet = mesh!(scene, Sphere(Point3f0(0), planet_radii[i]), color = :blue)
    translate!(planet, Point3f0(orbital_distances[i], 0, 0))
    push!(planet_meshes, planet)
end

# Function to update planet positions
function update_planet_positions!(planets, distances, time, speeds)
    for i in 1:length(planets)
        x = distances[i] * cos(time * speeds[i])
        y = distances[i] * sin(time * speeds[i])
        # Apply translation directly using translate!
        translate!(planets[i], Point3f0(x, y, 0))
    end
end

# Simulate animation
speeds = [1.0, 0.8, 0.5]  # Angular speeds for planets

# Create an Observable for time
t = Observable(0.0)

# Update planet positions when time changes
on(t) do time
    update_planet_positions!(planet_meshes, orbital_distances, time, speeds)
end

# Create animation
record(scene, "solar_system_animation.mp4", range(0, 10, length=300); framerate = 30) do time
    t[] = time
end

display(scene)