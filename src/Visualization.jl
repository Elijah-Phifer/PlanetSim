module Visualization

using Plots
using DataFrames
using GLMakie
using GeometryBasics
using ..Core: Simulation_env  
using ..PlanetManager
using ..Algorithms: run_algorithm

gr()

export Plot_Static, Static_interactive, Animate3D_interactive, Animate3D_GIF, save_gif

function Plot_Static(df::DataFrame)
    # Visualization code here
    # Group the data by planet so we can plot each orbit separately
    grouped_planets = groupby(df, :planet)

    # Initialize a 3D plot
    plt = Plots.plot(xlabel="x", ylabel="y", zlabel="z", title="Planetary Orbits", legend=:topright)

    # Plot each planet's orbit path
    for planet_data in grouped_planets
        planet_name = unique(planet_data.planet)[1]  # Get the planet's name
        Plots.plot!(plt, planet_data.x, planet_data.y, planet_data.z, label=planet_name)
    end

    return plt
end

function Static_interactive(algorithm::Symbol, df::DataFrame, sim::Simulation_env, sun_mass::Float64)
    grouped_planets = groupby(df, :planet)

    fig = Figure(resolution=(1200, 800))
    ax = Axis3(fig[1, 1], xlabel="x", ylabel="y", zlabel="z", aspect=:data, width=600, height=400)

    # Store the plot references in a simple array
    lines_plotted = []

    for planet_data in grouped_planets
        planet_name = unique(planet_data.planet)[1]
        line = lines!(ax, planet_data.x, planet_data.y, planet_data.z, label=planet_name)
        push!(lines_plotted, line)  # Store the reference to the line object
    end

    ax.title = "Planetary Orbits"

    # Create Sun mass slider
    slider = Slider(fig[2, 1], range=0.5:0.1:5.0, startvalue=sun_mass)
    
    # Display the current slider value
    Label(fig[2, 2], text=lift(slider.value) do v
        "Sun Mass: $v"
    end)

    # Button to re-run the simulation
    button = Button(fig[3, 1], label="Simulate")

    # Flag to prevent redundant simulation runs
    running_simulation = false

    on(button.clicks) do _
        if running_simulation
            println("Simulation already running.")
            return
        end

        # Set the flag to indicate that a simulation is running
        running_simulation = true

        # Extract the value from the Observable slider
        sun_mass_value = slider.value[] 
        println("Button pressed. Sun Mass from slider: $sun_mass_value")

        # Update the sun's mass in the simulation
        update_sun_mass!(sim, sun_mass_value) 

        # Rerun the simulation
        data = run_algorithm(algorithm, sim)
        grouped_planets = groupby(data, :planet)

        # Hide old lines before plotting new ones
        for line in lines_plotted
            line.visible = false  
        end

        # Clear the stored lines list
        empty!(lines_plotted)

        # Plot new orbits
        for planet_data in grouped_planets
            planet_name = unique(planet_data.planet)[1]
            line = lines!(ax, planet_data.x, planet_data.y, planet_data.z, label=planet_name)
            push!(lines_plotted, line) 
        end

        println("Simulation completed.")
        
        # Reset the flag after the simulation is done
        running_simulation = false
    end

    return fig
end

function Animate3D_interactive(df::DataFrame)

    # Read the orbital data from CSV
    #df = CSV.read(csv_path, DataFrame)
    unique_planets = unique(df.planet)
    time_steps = unique(df.time)
    
    # Create figure
    fig = Figure(size = (1200, 800))
    ax = Axis3(fig[1, 1], aspect = :data)
    hidedecorations!(ax)
    hidespines!(ax)
    
    # Define color palette and size scaling factors
    base_colors = Dict("Sun" => :yellow, "Jupiter" => :orange, "Saturn" => :gold, "Earth" => :green,
                        "Uranus" => :lightblue, "Neptune" => :blue, "Pluto" => :gray)
    default_color = :black
    size_scale = Dict("Sun" => 0.5, "Jupiter" => 0.3, "Saturn" => 0.25, "Earth" => 0.2,
                        "Uranus" => 0.2, "Neptune" => 0.2, "Pluto" => 0.1)
    default_size = 0.05
    
    # Generate colors and sizes based on unique planets
    planet_colors = Dict{String, Symbol}()
    planet_sizes = Dict{String, Float64}()
    
    for planet in unique_planets
        planet_colors[planet] = get(base_colors, planet, default_color)
        planet_sizes[planet] = get(size_scale, planet, default_size)
    end

    # Create planet meshes
    planet_meshes = Dict()
    for planet in unique_planets
        initial_data = first(filter(row -> row.planet == planet, df))
        initial_pos = Point3f0(initial_data.x, initial_data.y, initial_data.z)
        sphere = Sphere(initial_pos, Float32(planet_sizes[planet]))
        planet_meshes[planet] = mesh!(ax, sphere, color = planet_colors[planet])
    end

    # Create orbital paths
    for planet in unique_planets
        planet_data = filter(row -> row.planet == planet, df)
        planet_positions = [Point3f0(row.x, row.y, row.z) for row in eachrow(planet_data)]
        lines!(ax, planet_positions, color = (planet_colors[planet], 0.3))
    end

    # Animation function
    function update_scene(frame_idx)
        time_step = time_steps[frame_idx]
        frame_data = filter(row -> row.time == time_step, df)
        for row in eachrow(frame_data)
            new_pos = Point3f0(row.x, row.y, row.z)
            planet_meshes[row.planet][1] = Sphere(new_pos, (Float32(planet_sizes[row.planet])) )
        end
    end

    # Create animation
    frame = Observable(1)
    on(frame) do idx
        update_scene(idx)
    end

    # Animation loop
    @async while true
        for i in 1:length(time_steps)
            frame[] = i
            sleep(0.1)  # Control animation speed
        end
    end

    # Set camera position and perspective
    ax.azimuth = 1.5
    ax.elevation = 0.5

    # Adjust axis limits
    max_coord = maximum(abs.([df.x; df.y; df.z])) * 1.2
    GLMakie.xlims!(ax, -max_coord, max_coord)
    GLMakie.ylims!(ax, -max_coord, max_coord)
    GLMakie.zlims!(ax, -max_coord, max_coord)

    #display(fig)
    return fig

end

function Animate3D_GIF(df::DataFrame)
    # Ensure time column is ordered to maintain animation sequence
    unique_times = sort(unique(df.time))
    
    # Set up animation
    anim = @animate for t in unique_times
        # Filter data for the current time step
        df_time = filter(row -> row.time == t, df)
        
        # 3D scatter plot for this time step
        Plots.scatter(df_time.x, df_time.y, df_time.z, 
                group = df_time.planet, 
                markersize = 5,
                label = df_time.planet,
                xlims = (-30, 30), 
                ylims = (-30, 30), 
                zlims = (-30, 30),
                xlabel = "X", ylabel = "Y", zlabel = "Z", 
                title = "Planetary Orbits at t = $(round(t, digits=2))")
    end
    
    # Save animation as a GIF
    #gif(anim, filename, fps = 10)

    return anim
end

function save_gif(plt, filename)
    # Display the GIF in the notebook
    #display("image/gif", read(filename))
    gif(plt, filename, fps = 15)
end


end
