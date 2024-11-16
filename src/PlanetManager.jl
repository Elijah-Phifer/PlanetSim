module PlanetManager

using ..Core

export add_planet!, remove_planet!, number_of_planets, list_vels, list_pos, list_masses, update_sun_mass!


function add_planet!(sim::Simulation_env, planet::Planet)
    push!(sim.planets, planet)
end

function remove_planet!(sim::Simulation_env, planet::Planet)
    filter!(x -> x != planet, sim.planets)
end

function number_of_planets(sim::Simulation_env)
    return length(sim.planets)
end

function list_vels(planets::Vector{Planet})
    # Initialize an empty matrix with 3 rows (for x, y, z components)
    # and as many columns as there are planets
    vel_matrix = zeros(3, length(planets))
    
    # Fill each column with a planet's velocity
    for (i, planet) in enumerate(planets)
        vel_matrix[:, i] = planet.velocity
    end
    
    return vel_matrix
end

function list_pos(planets::Vector{Planet})
    # Initialize an empty matrix with 3 rows (for x, y, z components)
    # and as many columns as there are planets
    pos_matrix = zeros(3, length(planets))
    
    # Fill each column with a planet's position
    for (i, planet) in enumerate(planets)
        pos_matrix[:, i] = planet.position
    end
    
    return pos_matrix
end

function list_masses(planets::Vector{Planet})
    # Initialize an empty vector with as many elements as there are planets
    masses = zeros(length(planets))
    
    # Fill the vector with each planet's mass
    for (i, planet) in enumerate(planets)
        masses[i] = planet.mass
    end
    
    return masses
end

function update_sun_mass!(sim::Simulation_env, new_mass::Float64)
    for planet in sim.planets
        if planet.name == "Sun"
            planet.mass = new_mass  # Update the mass directly
            break
        end
    end
end

end
