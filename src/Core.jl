module Core

export Simulation_env, Planet

struct Planet
    name::String
    mass::Float64
    position::Vector{Float64}
    velocity::Vector{Float64}

end

struct Simulation_env
    planets::Vector{Planet}
    G::Float64
    t_end::Float64
end



end