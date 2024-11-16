module Algorithms

using ..Core
using ..PlanetManager
using DataFrames

using OrdinaryDiffEq, ModelingToolkit

using LinearAlgebra

export run_algorithm

const θ = 0.7         # threshold for Barnes-Hut approximation

function run_algorithm(algorithm::Symbol, sim::Simulation_env)# planets::Vector{Planet}, g::Float64)
    if algorithm == :direct_pairwise
        return direct_pairwise_simulation(sim)
    elseif algorithm == :Barnes_Hut
        return Barnes_Hut(sim)
    else
        throw(ArgumentError("Unknown algorithm: $algorithm"))
    end
end

function direct_pairwise_simulation(sim::Simulation_env)
    # Your simulation logic here
    #G = 6.67430e-11  # Gravitational constant
    position_data = DataFrame()
    G = sim.G
    planets = sim.planets

    vel = list_vels(planets)
    pos = list_pos(planets)
    M = list_masses(planets)
    tspan = (0.0, sim.t_end)
    ∑ = sum
    N = length(planets)
    @independent_variables t
    @variables t u(t)[1:3, 1:N]
    u = collect(u)
    D = Differential(t)
    potential = -G *
                ∑(
        i -> ∑(j -> (M[i] * M[j]) / √(∑(k -> (u[k, i] - u[k, j])^2, 1:3)), 1:(i - 1)),
        2:N)


    eqs = vec(@. D(D(u))) .~ .-ModelingToolkit.gradient(potential, vec(u)) ./
    repeat(M, inner = 3)
    @named sys = ODESystem(eqs, t)
    ss = structural_simplify(sys)
    prob = ODEProblem(ss, [vec(u .=> pos); vec(D.(u) .=> vel)], tspan)
    sol = solve(prob, Tsit5());

    for t in 1:length(sol.t)
        #plt = Plots.plot()

        for i in 1:number_of_planets(sim)
            # Extract entire path up to the current time t
            x_path = [sol[u[1, i], k] for k in 1:t]
            y_path = [sol[u[2, i], k] for k in 1:t]
            z_path = [sol[u[3, i], k] for k in 1:t]

            # Current position of the planet
            x = sol[u[1, i], t]
            y = sol[u[2, i], t]
            z = sol[u[3, i], t]

            # Append the current position to the DataFrame
            push!(position_data, (time=sol.t[t], planet=sim.planets[i].name, x=x, y=y, z=z))

        end

    end

    
    return position_data  #sol, u
end

function Barnes_Hut(sim::Simulation_env)
    position_data = DataFrame()
    planets = sim.planets
    G = sim.G
    
    # Initial conditions
    vel = list_vels(planets)
    pos = list_pos(planets)
    dt = 1  # Time step size
    num_steps = Int(sim.t_end / dt)
    
    # Current state
    current_pos = copy(pos)
    current_vel = copy(vel)
    
    for step in 1:num_steps
        # Create root node that encompasses all planets
        bounds = get_system_bounds(current_pos)
        root = create_root_node(bounds)
        
        # Insert all planets into the octree
        for (i, planet) in enumerate(planets)
            planet.position = current_pos[:, i]
            planet.velocity = current_vel[:, i]
            try
                insert_body!(root, planet, 0)  # Add depth parameter
            catch e
                @warn "Failed to insert planet $(planet.name): $e"
            end
        end
        
        # Calculate center of mass for all nodes
        try
            summarize_subtree!(root, 0)  # Add depth parameter
        catch e
            @warn "Failed to summarize tree: $e"
            continue  # Skip this timestep if tree building fails
        end
        
        # Calculate forces and update positions
        accelerations = zeros(3, length(planets))
        
        for (i, planet) in enumerate(planets)
            # Calculate net force on each planet
            force = compute_force(root, planet, G, θ, 0)  # Add depth parameter
            accelerations[:, i] = force / planet.mass
        end

        power_place = length(string(num_steps)) - 1

        if (power_place < 2)
            div = 10^(ceil(power_place))
        else
            div = 10^(ceil(power_place/2))
        end

        #println(div)

        
        # Update positions and velocities using leapfrog integration
        for i in 1:length(planets)
            # Update velocity (half step)
            current_vel[:, i] += 0.5 * dt * accelerations[:, i]
            
            # Update position (full step)
            current_pos[:, i] += dt * current_vel[:, i]
            
            # Update velocity (half step)
            current_vel[:, i] += 0.5 * dt * accelerations[:, i]

            
            if(step % div == 0)
                # Store position data
                push!(position_data, (
                    time = step * dt,
                    planet = planets[i].name,
                    x = current_pos[1, i],
                    y = current_pos[2, i],
                    z = current_pos[3, i]
                ))
            end
            

        end

    end
    
    return position_data
end

function get_system_bounds(positions)
    # Find the maximum extent of the system
    min_pos = vec(minimum(positions, dims=2))
    max_pos = vec(maximum(positions, dims=2))
    center = (min_pos + max_pos) / 2
    size = maximum(max_pos - min_pos) * 1.1  # Add 10% margin
    
    return Region3D(center, size)
end

function create_root_node(bounds::Region3D)
    return OctreeNode3D(bounds)
end

const MAX_DEPTH = 40  # Maximum tree depth to prevent stack overflow

function insert_body!(node::OctreeNode3D, body::Planet, depth::Int)
    if depth > MAX_DEPTH
        throw(ErrorException("Maximum tree depth exceeded"))
    end
    
    # If node is empty, put the body here
    if node.body === nothing && all(isnothing, node.children)
        node.body = body
        return
    end
    
    # If there's already a body here, create children
    if node.body !== nothing
        old_body = node.body
        node.body = nothing
        subdivide!(node)
        insert_body!(node, old_body, depth + 1)
    end
    
    # Insert the new body into appropriate child
    child_idx = get_octant(body.position, node.region.center)
    
    if child_idx < 1 || child_idx > 8
        throw(ErrorException("Invalid octant index: $child_idx"))
    end
    
    if node.children[child_idx] === nothing
        new_region = get_child_region(node.region, child_idx)
        node.children[child_idx] = OctreeNode3D(new_region)
    end
    
    insert_body!(node.children[child_idx], body, depth + 1)
end

function get_octant(pos::Vector{Float64}, center::Vector{Float64})
    # Determine which octant a position falls into
    idx = 1
    if pos[1] >= center[1] idx += 1 end
    if pos[2] >= center[2] idx += 2 end
    if pos[3] >= center[3] idx += 4 end
    return idx
end

function get_child_region(parent::Region3D, octant::Int)
    new_size = parent.size / 2
    new_center = copy(parent.center)
    
    # Adjust center based on octant
    offset = new_size / 2
    new_center[1] += ((octant - 1) & 1 > 0 ? offset : -offset)
    new_center[2] += ((octant - 1) & 2 > 0 ? offset : -offset)
    new_center[3] += ((octant - 1) & 4 > 0 ? offset : -offset)
    
    return Region3D(new_center, new_size)
end

function summarize_subtree!(node::OctreeNode3D, depth::Int)
    if depth > MAX_DEPTH
        throw(ErrorException("Maximum tree depth exceeded"))
    end
    
    if node.body !== nothing
        # Leaf node with a single body
        node.total_mass = node.body.mass
        node.com = copy(node.body.position)
        return
    end
    
    # Initialize
    node.total_mass = 0.0
    node.com = zeros(3)
    
    # Recursively summarize children
    for child in node.children
        if child !== nothing
            summarize_subtree!(child, depth + 1)
            node.total_mass += child.total_mass
            node.com .+= child.total_mass .* child.com
        end
    end
    
    if node.total_mass > 0
        node.com ./= node.total_mass
    end
end

function compute_force(node::OctreeNode3D, body::Planet, G::Float64, θ::Float64, depth::Int)
    if depth > MAX_DEPTH
        return zeros(3)
    end
    
    # If node is empty, no force
    if node.total_mass == 0
        return zeros(3)
    end
    
    # Vector from body to node's center of mass
    r = node.com - body.position
    r_mag = norm(r)
    
    # If this is a leaf node with our own body, skip it
    if node.body === body
        return zeros(3)
    end
    
    # Minimum distance to prevent numerical instabilities
    if r_mag < 1e-10
        return zeros(3)
    end
    
    # Check if node is far enough for approximation


    # This stuff works weird, needs more work!!! ###########

    # # Region size / distance ratio
    # size_to_distance = node.region.size / r_mag


    # # Smooth transition for force approximation
    # ε = 0.1  # Transition width, adjust as needed
    # if size_to_distance < θ - ε
    #     # Fully approximate using center of mass
    #     return G * node.total_mass * body.mass * r / (r_mag^3)
    # elseif size_to_distance > θ + ε
    #     # Fully resolve using children nodes
    #     force = zeros(3)
    #     for child in node.children
    #         if child !== nothing
    #             force .+= compute_force(child, body, G, θ, depth + 1)
    #         end
    #     end
    #     return force
    # else
    #     # Blend the two approaches
    #     approx_force = G * node.total_mass * body.mass * r / (r_mag^3)
    #     direct_force = zeros(3)
    #     for child in node.children
    #         if child !== nothing
    #             direct_force .+= compute_force(child, body, G, θ, depth + 1)
    #         end
    #     end
    #     # Weighted blend
    #     α = (size_to_distance - (θ - ε)) / (2 * ε)
    #     return α * direct_force + (1 - α) * approx_force
    # end

    #First try this works!!!!################
    if node.body !== nothing || (node.region.size / r_mag < θ)
        # Use this node's COM as an approximation
        return G * node.total_mass * body.mass * r / (r_mag^3)
    end
    
    # Otherwise, recursively compute forces from children
    force = zeros(3)
    for child in node.children
        if child !== nothing
            force .+= compute_force(child, body, G, θ, depth + 1)
        end
    end
    
    return force
end

function subdivide!(node::OctreeNode3D)
    # Create eight children nodes
    for i in 1:8
        region = get_child_region(node.region, i)
        node.children[i] = OctreeNode3D(region)
    end
end

end
