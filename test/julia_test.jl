using LinearAlgebra
using DataFrames
using Plots

mutable struct Planet
    position::Vector{Float64}
    velocity::Vector{Float64}
    mass::Float64
end

Base.show(io::IO, planet::Planet) = println(io, "Planet(position=$(planet.position), velocity=$(planet.velocity), mass=$(planet.mass))")

function calculate_force(body1::Planet, body2::Planet, G::Float64=2.95912208286e-4)
    """Calculate the gravitational force exerted on body1 by body2."""
    r_vector = body2.position - body1.position
    r_magnitude = norm(r_vector)
    if r_magnitude == 0.0
        return zeros(3)  # Avoid division by zero
    end
    r_unit = r_vector / r_magnitude
    force_magnitude = G * body1.mass * body2.mass / r_magnitude^2
    return force_magnitude .* r_unit
end

function update_positions_and_velocities!(bodies::Vector{Planet}, dt::Float64)
    """Update the positions and velocities of all bodies."""
    forces = [zeros(3) for _ in bodies]

    # Compute pairwise gravitational forces
    for i in eachindex(bodies)
        for j in eachindex(bodies)
            if i != j
                forces[i] += calculate_force(bodies[i], bodies[j])
            end
        end
    end

    # Update velocities and positions
    for i in eachindex(bodies)
        acceleration = forces[i] / bodies[i].mass
        bodies[i].velocity += acceleration .* dt
        bodies[i].position += bodies[i].velocity .* dt
    end
end

function simulate(bodies::Vector{Planet}, steps::Int, dt::Float64)
    """Run the N-body simulation for a given number of steps and save data for plotting."""
    data = DataFrame(time=Int[], planet=Int[], x=Float64[], y=Float64[], z=Float64[])

    for step in 1:steps
        # Record positions at each step
        for (i, body) in enumerate(bodies)
            push!(data, (step, i, body.position[1], body.position[2], body.position[3]))
        end

        # Update positions and velocities
        update_positions_and_velocities!(bodies, dt)
    end

    return data
end

function plot_static(df::DataFrame)
    """
    Visualize planetary orbits in 3D.
    Args:
        df (DataFrame): DataFrame with columns 'planet', 'x', 'y', and 'z'.

    Returns:
        None
    """
    grouped_planets = groupby(df, :planet)

    plt = plot3d(title="Planetary Orbits", xlabel="x", ylabel="y", zlabel="z")

    # Plot each planet's orbit path
    for group in grouped_planets
        plot3d!(group.x, group.y, group.z, label="Planet $(group.planet[1])")
    end

    display(plt)
end

# Main execution

# Define initial conditions (in AU, AU/day, and solar masses)
sun_mass = 1.0
Sun = Planet([0.0, 0.0, 0.0], [0.0, 0.0, 0.0], sun_mass)
Jupiter = Planet([-3.5023653, -3.8169847, -1.5507963],
                    [0.00565429, -0.0041249, -0.00190589],
                    0.000954786104043)

# Simulation parameters
steps = 100000
dt = 0.1  # Time step in days

# Run the simulation and save the position data
position_data = simulate([Sun, Jupiter], steps, dt)

# Plot the static 3D trajectories
plot_static(position_data)

