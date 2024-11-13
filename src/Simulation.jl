module Simulation

using ..Core

export initialize_simulation


function initialize_simulation(t_end::Float64, G::Float64=2.95912208286e-4)
    Simulation_env(Planet[], G, t_end)
end



end
