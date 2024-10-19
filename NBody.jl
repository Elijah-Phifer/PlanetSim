
using Plots, OrdinaryDiffEq, ModelingToolkit

struct Body
    name::String
    mass::Float64
    init_x::Float64
    init_y::Float64
    init_z::Float64
end

gr() 

G = 2.95912208286e-4

planets = Body[]

M = []

planets = []

t_span = (0.0, 400_000_000.0)



function createBody(name::String, mass::Float64, init_x::Float64, init_y::Float64, init_z::Float64)::Body
    return Body(name, mass, init_x, init_y, init_z)
end


# Define a function that appends a Body struct to an array
function addBody!( new_body::Body)
    push!(planets, new_body)  # push! modifies the array in place
end

# Example usage:
# Create an empty array of Body structs


# Create a new Body object
earth = Body("Earth", 5.972e24, 0.0, 0.0, 0.0)

# Append the new body to the array
addBody!(earth)

# Verify the array contains the new body
println(planets)

