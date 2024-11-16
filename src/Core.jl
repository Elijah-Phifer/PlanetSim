module Core

export Simulation_env, Planet, Region3D, OctreeNode3D


# Structure to represent a 3D region in space
struct Region3D
    center::Vector{Float64}
    size::Float64
end

mutable struct Planet
    name::String
    mass::Float64
    position::Vector{Float64}
    velocity::Vector{Float64}
    force::Vector{Float64}

    Planet(name, mass, position, velocity) = new(name, mass, copy(position), copy(velocity), zeros(3))
    
end

mutable struct OctreeNode3D
    region::Region3D
    body::Union{Planet, Nothing}
    total_mass::Float64
    com::Vector{Float64}  # center of mass
    children::Vector{Union{OctreeNode3D, Nothing}}
    
    function OctreeNode3D(region::Region3D)
        new(region, nothing, 0.0, zeros(3), 
            Vector{Union{OctreeNode3D, Nothing}}(nothing, 8))
    end
end

struct Simulation_env
    planets::Vector{Planet}
    G::Float64
    t_end::Float64
end


end
