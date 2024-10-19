module PlanetOrbitSimulator

using Plots, OrdinaryDiffEq, ModelingToolkit
gr()

export Planet, set_Simulation, number_of_planets ,add_planet!, run_simulation!, run_sim!

struct Planet
    name::String
    mass::Float64
    position::Vector{Float64}
    velocity::Vector{Float64}
end

mutable struct Simulation
    planets::Vector{Planet}
    G::Float64
    t_end::Float64
end

function number_of_planets(sim::Simulation)
    return length(sim.planets)
end


function set_Simulation(t_end::Float64, G::Float64=2.95912208286e-4)
    Simulation(Planet[], G, t_end)
end

function add_planet!(sim::Simulation, planet::Planet)
    push!(sim.planets, planet)
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

function calculate_simu(sim::Simulation, planets::Vector{Planet}, G::Float64)
    #G = 6.67430e-11  # Gravitational constant
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
    
    return sol, u
end

function calculate_sim(sim::Simulation, planets::Vector{Planet}, G::Float64)
    vel = list_vels(planets)
    pos = list_pos(planets)
    M = list_masses(planets)
    tspan = (0.0, sim.t_end)
    ∑ = sum
    N = length(planets)
    @parameters t
    @variables u(..)[1:3, 1:N]
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
    sol = solve(prob, Tsit5(), reltol=1e-8, abstol=1e-8);
    
    return sol
end

# function update_planet!(planet::Planet, acceleration::Vector{Float64}, dt::Float64)
#     planet.velocity += acceleration * dt
#     planet.position += planet.velocity * dt
# end

function run_simulation!(sim::Simulation)
    sol, u = calculate_simu(sim, sim.planets, sim.G)
    return sol, u
end

function run_sim!(sim::Simulation)
    sol = calculate_sim(sim, sim.planets, sim.G)
    return sol
end

end # module