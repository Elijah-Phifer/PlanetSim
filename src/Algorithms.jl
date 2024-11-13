module Algorithms

using ..Core
using ..PlanetManager
using DataFrames

using OrdinaryDiffEq, ModelingToolkit

export run_algorithm

function run_algorithm(algorithm::Symbol, sim::Simulation_env)# planets::Vector{Planet}, g::Float64)
    if algorithm == :direct_pairwise
        return direct_pairwise_simulation(sim)
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

            # Plot the orbit path
           # plot!(plt, x_path, y_path, z_path, label=simu.planets[i].name)

            # Plot the moving planet as a ball
           # scatter!(plt, [x], [y], [z], label="", marker=:circle)
        end

        # Save the position data to a CSV file
        #CSV.write("planetary_positions.csv", position_data)

        #plot!(plt; xlab = "x", ylab = "y", zlab = "z", title = "Outer solar system", legend=false)
        #frame(anim)
    end

    
    return position_data  #sol, u
end

end
